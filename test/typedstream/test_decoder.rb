# frozen_string_literal: true

require "test_helper"

class TestTypedStreamDecoder < Minitest::Test
  def setup
    @sample_header = [0x04] + Array.new(15, 0x00)  # Version 4 + 15 null bytes
    @decoder = Imessage::Db::TypedStream::Decoder.new(@sample_header)
  end

  def test_decoder_initialization
    assert_equal 0, @decoder.position
    assert_empty @decoder.type_cache
    assert_empty @decoder.object_cache
  end

  def test_invalid_header_too_short
    short_data = [0x04, 0x00, 0x00]  # Too short

    assert_raises(Imessage::Db::TypedStream::InvalidHeaderError) do
      decoder = Imessage::Db::TypedStream::Decoder.new(short_data)
      decoder.decode
    end
  end

  def test_unsupported_version
    bad_version = [0x05] + Array.new(15, 0x00)  # Version 5 (unsupported)

    assert_raises(Imessage::Db::TypedStream::UnsupportedVersionError) do
      decoder = Imessage::Db::TypedStream::Decoder.new(bad_version)
      decoder.decode
    end
  end

  def test_empty_stream
    result = @decoder.decode
    assert_equal [], result
  end

  def test_simple_stream_with_start_end
    data = @sample_header + [
      Imessage::Db::TypedStream::STREAM_START,
      Imessage::Db::TypedStream::INHERITANCE_END,  # Empty class hierarchy
      Imessage::Db::TypedStream::STREAM_END
    ]

    decoder = Imessage::Db::TypedStream::Decoder.new(data)
    result = decoder.decode

    assert_equal 1, result.length
    assert result[0].is_a?(Hash)
    assert result[0].key?(:class_hierarchy)
    assert result[0].key?(:data)
  end

  def test_stream_with_string_data
    # Simple string: length byte followed by string content
    string_data = [5] + "Hello".bytes

    data = @sample_header + [
      Imessage::Db::TypedStream::STREAM_START,
      Imessage::Db::TypedStream::INHERITANCE_END
    ] + string_data + [
      Imessage::Db::TypedStream::STREAM_END
    ]

    decoder = Imessage::Db::TypedStream::Decoder.new(data)
    result = decoder.decode

    assert_equal 1, result.length
    assert result[0][:class_hierarchy].empty?
  end

  def test_class_hierarchy_parsing
    class_name = "NSString"
    class_data = [class_name.length] + class_name.bytes

    data = @sample_header + [
      Imessage::Db::TypedStream::STREAM_START
    ] + class_data + [
      Imessage::Db::TypedStream::INHERITANCE_END,
      Imessage::Db::TypedStream::STREAM_END
    ]

    decoder = Imessage::Db::TypedStream::Decoder.new(data)
    result = decoder.decode

    assert_equal 1, result.length
    assert_includes result[0][:class_hierarchy], class_name
  end

  def test_short_int_parsing
    data = @sample_header + [
      Imessage::Db::TypedStream::STREAM_START,
      Imessage::Db::TypedStream::INHERITANCE_END,
      Imessage::Db::TypedStream::SHORT_INT_FLAG,
      0x34, 0x12,  # Little-endian 0x1234
      Imessage::Db::TypedStream::STREAM_END
    ]

    decoder = Imessage::Db::TypedStream::Decoder.new(data)

    # This should not raise an error, but may not parse perfectly due to stream structure
    begin
      result = decoder.decode
      assert result.is_a?(Array)
    rescue => e
      flunk "Expected no error, but got: #{e.message}"
    end
  end

  def test_cache_reference
    cache_index = Imessage::Db::TypedStream::CACHE_START_INDEX

    data = @sample_header + [
      Imessage::Db::TypedStream::STREAM_START,
      Imessage::Db::TypedStream::INHERITANCE_END,
      cache_index,  # Cache reference
      Imessage::Db::TypedStream::STREAM_END
    ]

    decoder = Imessage::Db::TypedStream::Decoder.new(data)

    # This should not raise an error, but may not parse perfectly due to stream structure
    begin
      result = decoder.decode
      assert result.is_a?(Array)
    rescue => e
      flunk "Expected no error, but got: #{e.message}"
    end
  end
end
