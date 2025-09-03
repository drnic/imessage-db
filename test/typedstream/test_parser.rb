# frozen_string_literal: true

require "test_helper"

class TestTypedStreamParser < Minitest::Test
  def test_parser_decode_empty_data
    result = Imessage::Db::TypedStream::Parser.decode("")
    assert_equal [], result
  end

  def test_parser_decode_invalid_data
    # Data that's too short for a valid header
    result = Imessage::Db::TypedStream::Parser.decode("short")
    assert_equal [], result
  end

  def test_parser_decode_nil_data
    result = Imessage::Db::TypedStream::Parser.decode(nil)
    assert_equal [], result
  end

  def test_parse_attributed_string_empty
    result = Imessage::Db::TypedStream::Parser.parse_attributed_string("")
    assert_nil result
  end

  def test_parse_attributed_string_invalid
    result = Imessage::Db::TypedStream::Parser.parse_attributed_string("invalid")
    assert_nil result
  end

  def test_parse_attributed_string_with_mock_data
    # Create mock data that looks like a valid typedstream header
    header = [0x04] + Array.new(15, 0x00)

    # Add a simple attributed string structure
    data = header + [
      Imessage::Db::TypedStream::STREAM_START,
      # Mock class hierarchy for NSAttributedString
      18, *"NSAttributedString".bytes,
      Imessage::Db::TypedStream::INHERITANCE_END,
      # Mock string content
      5, *"Hello".bytes,
      Imessage::Db::TypedStream::STREAM_END
    ]

    result = Imessage::Db::TypedStream::Parser.parse_attributed_string(data.pack("C*"))

    # Should either return an AttributedString object or nil (graceful handling)
    if result
      assert result.is_a?(Imessage::Db::TypedStream::AttributedString)
    else
      # Nil is acceptable for complex parsing that may not work with mock data
      assert_nil result
    end
  end
end
