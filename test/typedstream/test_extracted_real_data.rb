# frozen_string_literal: true

require "test_helper"

class TestExtractedRealData < Minitest::Test
  def setup
    # Real TypedStream data extracted from iMessage database

    # Message 155181 - "Yep" text message
    @message_155181_data = "\x04\vstreamtyped\x81\xE8\x03\x84\x01@\x84\x84\x84\x12NSAttributedString\x00\x84\x84\bNSObject\x00\x85\x92\x84\x84\x84\bNSString\x01\x94\x84\x01+\x03Yep\x86\x84\x02iI\x01\x03\x92\x84\x84\x84\fNSDictionary\x00\x94\x84\x01i\x01\x92\x84\x96\x96\x1D__kIMMessagePartAttributeName\x86\x92\x84\x84\x84\bNSNumber\x00\x84\x84\aNSValue\x00\x94\x84\x01*\x84\x99\x99\x00\x86\x86\x86"
    @message_155181_expected = "Yep"

    # Message 155192 - File transfer placeholder (contains special chars)
    @message_155192_data = "\x04\vstreamtyped\x81\xE8\x03\x84\x01@\x84\x84\x84\x12NSAttributedString\x00\x84\x84\bNSObject\x00\x85\x92\x84\x84\x84\bNSString\x01\x94\x84\x01+\x03\xEF\xBF\xBC\x86\x84\x02iI\x01\x01\x92\x84\x84\x84\fNSDictionary\x00\x94\x84\x01i\x01\x92\x84\x96\x96\"__kIMFileTransferGUIDAttributeName\x86\x92\x84\x84\x84\bNSString\x01\x94\x84\x01+$7AF06CBC-F077-41B4-B482-BDE6E045A25E\x86\x86\x86"
    @message_155192_expected = "\uFFFC"  # Object replacement character

    # Message 155194 - "Shit look at times on that" (already working correctly)
    @message_155194_data = "\x04\vstreamtyped\x81\xE8\x03\x84\x01@\x84\x84\x84\x12NSAttributedString\x00\x84\x84\bNSObject\x00\x85\x92\x84\x84\x84\bNSString\x01\x94\x84\x01+\x1BShit look at times on that\x86\x84\x02iI\x01\x1B\x92\x84\x84\x84\fNSDictionary\x00\x94\x84\x01i\x01\x92\x84\x96\x96\x1D__kIMMessagePartAttributeName\x86\x92\x84\x84\x84\bNSNumber\x00\x84\x84\aNSValue\x00\x94\x84\x01*\x84\x99\x99\x00\x86\x86\x86"
    @message_155194_expected = "Shit look at times on that"

    # Message 155196 - Another file transfer with multiple placeholders
    @message_155196_data = "\x04\vstreamtyped\x81\xE8\x03\x84\x01@\x84\x84\x84\x12NSAttributedString\x00\x84\x84\bNSObject\x00\x85\x92\x84\x84\x84\bNSString\x01\x94\x84\x01+\x06\xEF\xBF\xBC\xEF\xBF\xBC\x86\x84\x02iI\x01\x01\x92\x84\x84\x84\fNSDictionary\x00\x94\x84\x02i\x02\x92\x84\x96\x96\"__kIMFileTransferGUIDAttributeName\x86\x92\x84\x84\x84\bNSString\x01\x94\x84\x01+$C8B847A3-806B-42D6-8C19-BA7D4E9A1234\x86\x96\x96\"__kIMFileTransferGUIDAttributeName\x86\x92\x84\x84\x84\bNSString\x01\x94\x84\x01+$9FE847A3-806B-42D6-8C19-BA7D4E9A5678\x86\x86\x86"
    @message_155196_expected = "\uFFFC\uFFFC"  # Two object replacement characters

    # Message 155197 - Long text getting truncated (FAILING)
    @message_155197_data = "\u0004\vstreamtyped\x81\xE8\u0003\x84\u0001@\x84\x84\x84\u0012NSAttributedString\u0000\x84\x84\bNSObject\u0000\x85\x92\x84\x84\x84\bNSString\u0001\x94\x84\u0001+kSo, SPLC didn't let C do long jump as 3 other ppl in his age group were doing. So he did javalin earlier \x86\x84\u0002iI\u0001i\x92\x84\x84\x84\fNSDictionary\u0000\x94\x84\u0001i\u0001\x92\x84\x96\x96\u001D__kIMMessagePartAttributeName\x86\x92\x84\x84\x84\bNSNumber\u0000\x84\x84\aNSValue\u0000\x94\x84\u0001*\x84\x99\x99\u0000\x86\x86\x86"
    @message_155197_expected = "So, SPLC didn't let C do long jump as 3 other ppl in his age group were doing. So he did javalin earlier "
  end

  def test_message_155181_yep
    # Test simple text message
    attr_string = Imessage::Db::TypedStream::Parser.parse_attributed_string(@message_155181_data)

    refute_nil attr_string, "Should successfully parse message 155181"
    assert_instance_of Imessage::Db::TypedStream::AttributedString, attr_string

    actual_text = attr_string.plain_text
    assert_equal @message_155181_expected, actual_text,
      "Expected '#{@message_155181_expected}', got '#{actual_text}'"
  end

  def test_message_155192_file_transfer
    # Test file transfer placeholder
    attr_string = Imessage::Db::TypedStream::Parser.parse_attributed_string(@message_155192_data)

    refute_nil attr_string, "Should successfully parse message 155192"
    assert_instance_of Imessage::Db::TypedStream::AttributedString, attr_string

    actual_text = attr_string.plain_text
    assert_equal @message_155192_expected, actual_text,
      "Expected object replacement char, got '#{actual_text.inspect}'"
  end

  def test_message_155194_working_correctly
    # Test the message that already works correctly
    attr_string = Imessage::Db::TypedStream::Parser.parse_attributed_string(@message_155194_data)

    refute_nil attr_string, "Should successfully parse message 155194"
    assert_instance_of Imessage::Db::TypedStream::AttributedString, attr_string

    actual_text = attr_string.plain_text
    assert_equal @message_155194_expected, actual_text,
      "Expected '#{@message_155194_expected}', got '#{actual_text}'"
  end

  def test_message_155196_multiple_file_transfers
    # Test message with multiple file transfer placeholders
    attr_string = Imessage::Db::TypedStream::Parser.parse_attributed_string(@message_155196_data)

    refute_nil attr_string, "Should successfully parse message 155196"
    assert_instance_of Imessage::Db::TypedStream::AttributedString, attr_string

    actual_text = attr_string.plain_text
    assert_equal @message_155196_expected, actual_text,
      "Expected two object replacement chars, got '#{actual_text.inspect}'"
  end

  def test_message_155197_long_text_truncation
    # Test long text message that's getting truncated
    attr_string = Imessage::Db::TypedStream::Parser.parse_attributed_string(@message_155197_data)

    refute_nil attr_string, "Should successfully parse message 155197"
    assert_instance_of Imessage::Db::TypedStream::AttributedString, attr_string

    actual_text = attr_string.plain_text
    assert_equal @message_155197_expected, actual_text,
      "Expected full text '#{@message_155197_expected}', got '#{actual_text}'"
  end

  def test_extracted_messages_have_attributes
    # Test that these messages can extract attributes when present
    [@message_155181_data, @message_155192_data, @message_155194_data, @message_155196_data, @message_155197_data].each_with_index do |data, i|
      attr_string = Imessage::Db::TypedStream::Parser.parse_attributed_string(data)
      refute_nil attr_string, "Message #{i} should parse successfully"

      # The attributes might be empty {}, but the method should not crash
      attributes = attr_string.attributes
      assert attributes.is_a?(Hash), "Attributes should be a hash for message #{i}"
    end
  end

  def test_performance_with_extracted_data
    # Ensure parser doesn't hang with real data
    start_time = Time.now

    [@message_155181_data, @message_155192_data, @message_155194_data, @message_155196_data, @message_155197_data].each do |data|
      5.times do
        Imessage::Db::TypedStream::Parser.parse_attributed_string(data)
      end
    end

    elapsed = Time.now - start_time
    assert_operator elapsed, :<, 1.0, "Parser should handle extracted data quickly (took #{elapsed.round(3)}s)"
  end

  def test_debug_string_extraction_priorities
    # Debug test to understand string extraction order
    skip unless ENV["DEBUG"]

    puts "\n=== String Extraction Debug ==="

    [@message_155181_data, @message_155192_data, @message_155196_data, @message_155197_data].each_with_index do |data, i|
      puts "\nMessage #{[155181, 155192, 155196, 155197][i]}:"

      # Parse at low level to see all objects
      objects = Imessage::Db::TypedStream::Parser.decode(data)
      objects.each_with_index do |obj, j|
        puts "  Object #{j}: #{obj}"
        if obj[:data]
          puts "    Data keys: #{obj[:data].keys}"
          obj[:data].each do |k, v|
            puts "      #{k}: #{v.inspect}" if v.is_a?(String)
          end
        end
      end

      # Test extraction
      attr_string = Imessage::Db::TypedStream::Parser.parse_attributed_string(data)
      puts "  Extracted: '#{attr_string&.plain_text}'"
    end
  end
end
