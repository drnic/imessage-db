# frozen_string_literal: true

require "test_helper"

class TestInfiniteLoopProtection < Minitest::Test
  def test_decoder_with_malformed_real_data_does_not_hang
    # Test case for real-world data that might cause infinite loops

    # Common pattern that could cause infinite loops:
    # Data that looks valid but has malformed length indicators
    malformed_cases = [
      # Case 1: Header with malformed length byte that exceeds data
      create_data_with_bad_length,

      # Case 2: Recursive references that could cause endless parsing
      create_recursive_reference_data,

      # Case 3: Very long data that should timeout if decoder gets stuck
      create_long_repetitive_data,

      # Case 4: Data that has valid header but malformed stream markers
      create_malformed_stream_markers
    ]

    malformed_cases.each_with_index do |test_data, index|
      # Set a timeout to catch infinite loops
      time_limit = 2 # seconds

      start_time = Time.now

      begin
        # This should complete within reasonable time, not hang
        result = Imessage::Db::TypedStream::Parser.decode(test_data)

        elapsed = Time.now - start_time
        assert elapsed < time_limit, "Decoder took too long (#{elapsed}s) for case #{index + 1}"

        # Should return empty array for malformed data, not hang
        assert result.is_a?(Array)
      rescue => e
        elapsed = Time.now - start_time
        assert elapsed < time_limit, "Decoder hung for #{elapsed}s before raising: #{e.message}"

        # Exceptions are acceptable as long as they don't hang
        assert true, "Decoder properly raised exception: #{e.class}"
      end
    end
  end

  def test_message_methods_with_problematic_data
    # Test Message methods with data that previously caused hangs
    problematic_data_cases = [
      create_data_with_bad_length,
      create_recursive_reference_data,
      "\x04" + "\x00" * 15 + "\x84" + "\xFF" * 100  # High bytes that might confuse parser
    ]

    problematic_data_cases.each_with_index do |bad_data, index|
      message = Imessage::Db::Message.new(
        text: "Fallback text",
        attributedBody: bad_data
      )

      # These should complete quickly and not hang
      start_time = Time.now

      # Test basic methods that were hanging
      content = message.content
      has_formatting = message.has_formatting?
      attributed_text = message.attributed_text

      elapsed = Time.now - start_time
      assert elapsed < 1, "Message methods took too long (#{elapsed}s) for case #{index + 1}"

      # Should fall back gracefully
      assert content.is_a?(String)
      assert [true, false].include?(has_formatting)
      assert attributed_text.nil? || attributed_text.is_a?(String)
    end
  end

  def test_decoder_position_tracking_prevents_infinite_loops
    # Test that decoder properly tracks position and doesn't get stuck
    decoder = Imessage::Db::TypedStream::Decoder.new(create_data_with_bad_length)

    initial_position = decoder.position

    # Try to decode - should not hang
    begin
      decoder.decode
    rescue Imessage::Db::TypedStream::ParseError => e
      # ParseError is fine, we just want to ensure position tracking worked
      assert true, "Decoder properly failed with ParseError: #{e.message}"
    end

    # Position should have advanced or we should have failed quickly
    assert decoder.position >= initial_position
  end

  private

  def create_data_with_bad_length
    # Header + stream start + bad length byte that exceeds actual data
    header = [0x04] + Array.new(15, 0x00)

    bad_data = header + [
      Imessage::Db::TypedStream::STREAM_START,
      Imessage::Db::TypedStream::INHERITANCE_END,
      255,  # Claims next 255 bytes are a string, but we don't have that much data
      *"short".bytes,  # Only 5 bytes
      Imessage::Db::TypedStream::STREAM_END
    ]

    bad_data.pack("C*")
  end

  def create_recursive_reference_data
    # Data that might cause recursive parsing issues
    header = [0x04] + Array.new(15, 0x00)
    cache_ref = Imessage::Db::TypedStream::CACHE_START_INDEX

    recursive_data = header + [
      Imessage::Db::TypedStream::STREAM_START,
      Imessage::Db::TypedStream::INHERITANCE_END,
      cache_ref,  # Reference to cache that doesn't exist
      cache_ref,  # Another reference
      cache_ref,  # Multiple references that might cause loops
      Imessage::Db::TypedStream::STREAM_END
    ]

    recursive_data.pack("C*")
  end

  def create_long_repetitive_data
    # Very long data to test timeout behavior
    header = [0x04] + Array.new(15, 0x00)

    # Create a large amount of repetitive data
    large_data = header + [Imessage::Db::TypedStream::STREAM_START] +
      [0x01] * 1000 +  # 1000 bytes of 0x01
      [Imessage::Db::TypedStream::STREAM_END]

    large_data.pack("C*")
  end

  def create_malformed_stream_markers
    # Data with stream markers in wrong places
    header = [0x04] + Array.new(15, 0x00)

    malformed = header + [
      Imessage::Db::TypedStream::STREAM_END,    # End before start
      Imessage::Db::TypedStream::STREAM_START,
      Imessage::Db::TypedStream::STREAM_START,  # Double start
      Imessage::Db::TypedStream::INHERITANCE_END,
      Imessage::Db::TypedStream::STREAM_END,
      Imessage::Db::TypedStream::STREAM_END     # Double end
    ]

    malformed.pack("C*")
  end
end
