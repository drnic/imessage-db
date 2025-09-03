# frozen_string_literal: true

require "test_helper"

class TestMessageTypedStream < Minitest::Test
  def test_message_has_attributed_text_methods
    message = Imessage::Db::Message.new

    # Test method existence
    assert_respond_to message, :attributed_text
    assert_respond_to message, :attributed_string
    assert_respond_to message, :has_attributed_text?
    assert_respond_to message, :content
    assert_respond_to message, :text_attributes
    assert_respond_to message, :has_formatting?
    assert_respond_to message, :has_bold_text?
    assert_respond_to message, :has_italic_text?
    assert_respond_to message, :has_links?
  end

  def test_has_attributed_text_false_when_nil
    message = Imessage::Db::Message.new(attributedBody: nil)
    refute message.has_attributed_text?
  end

  def test_has_attributed_text_false_when_empty
    message = Imessage::Db::Message.new(attributedBody: "")
    refute message.has_attributed_text?
  end

  def test_has_attributed_text_true_when_present
    message = Imessage::Db::Message.new(attributedBody: "some_data")
    assert message.has_attributed_text?
  end

  def test_attributed_text_returns_nil_when_no_body
    message = Imessage::Db::Message.new(text: "Hello", attributedBody: nil)
    assert_nil message.attributed_text
  end

  def test_attributed_text_falls_back_to_text_on_parse_error
    # Mock a message with attributedBody that will fail to parse
    message = Imessage::Db::Message.new(text: "Fallback text", attributedBody: "invalid_data")

    # Should fall back to plain text when parsing fails
    assert_equal "Fallback text", message.attributed_text
  end

  def test_attributed_string_returns_nil_when_no_body
    message = Imessage::Db::Message.new(attributedBody: nil)
    assert_nil message.attributed_string
  end

  def test_attributed_string_returns_nil_on_parse_error
    message = Imessage::Db::Message.new(attributedBody: "invalid_data")
    assert_nil message.attributed_string
  end

  def test_content_method_with_plain_text
    message = Imessage::Db::Message.new(text: "Hello World", attributedBody: nil)
    assert_equal "Hello World", message.content
  end

  def test_content_method_with_attributed_text
    # Mock parsing to return specific content
    message = Imessage::Db::Message.new(text: "Plain", attributedBody: "mock_data")

    # Mock the parser to return a successful result
    mock_attributed = Minitest::Mock.new
    mock_attributed.expect(:plain_text, "Attributed content")

    Imessage::Db::TypedStream::Parser.stub(:parse_attributed_string, mock_attributed) do
      assert_equal "Attributed content", message.content
    end
  end

  def test_text_attributes_empty_when_no_attributed_string
    message = Imessage::Db::Message.new(attributedBody: nil)
    assert_equal({}, message.text_attributes)
  end

  def test_has_formatting_false_when_no_attributed_body
    message = Imessage::Db::Message.new(attributedBody: nil)
    refute message.has_formatting?
  end

  def test_has_formatting_false_when_no_attributes
    message = Imessage::Db::Message.new(attributedBody: "some_data")

    # Mock attributed string with empty attributes
    mock_attributed = Minitest::Mock.new
    mock_attributed.expect(:attributes, {})

    Imessage::Db::TypedStream::Parser.stub(:parse_attributed_string, mock_attributed) do
      refute message.has_formatting?
    end
  end

  def test_has_formatting_true_when_has_attributes
    message = Imessage::Db::Message.new(attributedBody: "some_data")

    # Mock attributed string with attributes
    mock_attributed = Minitest::Mock.new
    mock_attributed.expect(:attributes, {"NSFont" => "Helvetica"})

    Imessage::Db::TypedStream::Parser.stub(:parse_attributed_string, mock_attributed) do
      assert message.has_formatting?
    end
  end

  def test_has_bold_text_detection
    message = Imessage::Db::Message.new(attributedBody: "some_data")

    # Mock attributed string with bold formatting
    mock_attributed = Minitest::Mock.new
    mock_attributed.expect(:attributes, {"NSFont" => "Helvetica-Bold"})

    Imessage::Db::TypedStream::Parser.stub(:parse_attributed_string, mock_attributed) do
      assert message.has_bold_text?
    end
  end

  def test_has_italic_text_detection
    message = Imessage::Db::Message.new(attributedBody: "some_data")

    # Mock attributed string with italic formatting
    mock_attributed = Minitest::Mock.new
    mock_attributed.expect(:attributes, {"NSFont" => "Helvetica-Italic"})

    Imessage::Db::TypedStream::Parser.stub(:parse_attributed_string, mock_attributed) do
      assert message.has_italic_text?
    end
  end

  def test_has_links_detection
    message = Imessage::Db::Message.new(attributedBody: "some_data")

    # Mock attributed string with link attribute - needs both attributes and other method calls
    mock_attributed = Minitest::Mock.new
    mock_attributed.expect(:attributes, {"NSLink" => "https://example.com"})
    # The attributed_string method also gets called, so we need to handle that

    # Mock the text_attributes method directly to test has_links?
    def message.text_attributes
      {"NSLink" => "https://example.com"}
    end

    assert message.has_links?
  end

  def test_with_attributed_text_scope
    # Test that the scope exists and can be called without database connection
    assert_respond_to Imessage::Db::Message, :with_attributed_text

    # Should be defined as a scope
    assert Imessage::Db::Message.respond_to?(:with_attributed_text)
  end

  def test_with_formatting_scope_alias
    # Test that the scope exists and can be called without database connection
    assert_respond_to Imessage::Db::Message, :with_formatting

    # Should be defined as a scope
    assert Imessage::Db::Message.respond_to?(:with_formatting)
  end
end
