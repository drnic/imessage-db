# frozen_string_literal: true

require "test_helper"

class TestTypedStreamIntegration < Minitest::Test
  def test_message_model_integration_with_attributed_text
    # Test the complete flow of accessing attributed text from messages
    messages = create_test_messages_with_attributed_content

    messages.each do |message|
      # Test basic attributed text functionality
      if message.has_attributed_text?
        content = message.content
        assert content.is_a?(String)

        # Should have both attributed_text and fallback to regular text
        attributed = message.attributed_text
        assert attributed.nil? || attributed.is_a?(String)

        # Should be able to check formatting
        formatting = message.has_formatting?
        assert [true, false].include?(formatting)
      else
        # Messages without attributed body should fall back gracefully
        assert_nil message.attributed_text
        assert_equal message.text, message.content
        refute message.has_formatting?
      end
    end
  end

  def test_attributed_string_creation_and_methods
    # Test creating AttributedString objects manually
    attr_string = Imessage::Db::TypedStream::AttributedString.new(
      "Hello World",
      {"NSFont" => "Helvetica-Bold", "NSColor" => "red"}
    )

    assert_equal "Hello World", attr_string.string
    assert_equal "Hello World", attr_string.plain_text
    assert_equal "Hello World", attr_string.to_s
    assert attr_string.has_attributes?

    expected_hash = {string: "Hello World", attributes: {"NSFont" => "Helvetica-Bold", "NSColor" => "red"}}
    assert_equal expected_hash, attr_string.to_h
  end

  def test_message_formatting_detection
    # Test all the formatting detection methods
    message = create_message_with_mock_formatting

    # Mock different types of formatting
    {
      bold: {"NSFont" => "Helvetica-Bold"},
      italic: {"NSFont" => "Helvetica-Italic"},
      links: {"NSLink" => "https://example.com"},
      mixed: {"NSFont" => "Helvetica-BoldItalic", "NSLink" => "https://example.com"}
    }.each do |type, attributes|
      def message.text_attributes
        @test_attributes
      end

      message.instance_variable_set(:@test_attributes, attributes)

      case type
      when :bold
        assert message.has_bold_text?, "Should detect bold text with attributes: #{attributes}"
        refute message.has_italic_text?
        refute message.has_links?
      when :italic
        refute message.has_bold_text?
        assert message.has_italic_text?, "Should detect italic text with attributes: #{attributes}"
        refute message.has_links?
      when :links
        refute message.has_bold_text?
        refute message.has_italic_text?
        assert message.has_links?, "Should detect links with attributes: #{attributes}"
      when :mixed
        assert message.has_bold_text?, "Should detect bold in mixed formatting"
        assert message.has_italic_text?, "Should detect italic in mixed formatting"
        assert message.has_links?, "Should detect links in mixed formatting"
      end

      assert message.has_formatting?, "Should detect formatting for #{type}"
    end
  end

  def test_scopes_work_with_database
    # Test that our new scopes work properly
    message_class = Imessage::Db::Message

    # These should not raise errors
    scope_methods = [:with_attributed_text, :with_formatting]
    scope_methods.each do |scope_method|
      assert_respond_to message_class, scope_method

      # Calling the scope should return an ActiveRecord::Relation
      relation = message_class.send(scope_method)
      assert relation.is_a?(ActiveRecord::Relation)
    end
  end

  def test_typedstream_parser_robustness
    # Test parser with various edge cases
    test_cases = [
      "",              # Empty string
      nil,             # Nil input
      "invalid",       # Invalid data
      "\x00" * 100,    # Null bytes
      "random text",   # Random text
      [0x04].pack("C") # Just version byte
    ]

    test_cases.each do |test_data|
      result = Imessage::Db::TypedStream::Parser.decode(test_data)
      assert result.is_a?(Array), "decode should always return an array for input: #{test_data.inspect}"

      attr_result = Imessage::Db::TypedStream::Parser.parse_attributed_string(test_data)
      assert attr_result.nil? || attr_result.is_a?(Imessage::Db::TypedStream::AttributedString),
        "parse_attributed_string should return nil or AttributedString for input: #{test_data.inspect}"
    end
  end

  private

  def create_test_messages_with_attributed_content
    [
      # Message with attributedBody
      Imessage::Db::Message.new(
        text: "Hello World",
        attributedBody: "mock_attributed_data"
      ),
      # Message without attributedBody
      Imessage::Db::Message.new(
        text: "Plain text message",
        attributedBody: nil
      ),
      # Message with empty attributedBody
      Imessage::Db::Message.new(
        text: "Another plain message",
        attributedBody: ""
      )
    ]
  end

  def create_message_with_mock_formatting
    Imessage::Db::Message.new(
      text: "Formatted message",
      attributedBody: "mock_data"
    )
  end
end
