#!/usr/bin/env ruby
# frozen_string_literal: true

# Example script demonstrating Apple TypedStream functionality
# This script shows how to use the typedstream decoder with iMessage data

require_relative "../lib/imessage/db"

puts "=== Apple TypedStream Integration for iMessage ==="
puts

# Example 1: Basic TypedStream parsing
puts "1. Basic TypedStream Parsing"
puts "-" * 40

# Create some sample binary data that looks like a typedstream
sample_data = [0x04] + Array.new(15, 0x00) + [
  Imessage::Db::TypedStream::STREAM_START,
  8, *"NSString".bytes,
  Imessage::Db::TypedStream::INHERITANCE_END,
  11, *"Hello World".bytes,
  Imessage::Db::TypedStream::STREAM_END
]

puts "Sample typedstream data: #{sample_data.length} bytes"
result = Imessage::Db::TypedStream::Parser.decode(sample_data.pack("C*"))
puts "Decoded objects: #{result.length}"
puts "First object: #{result.first.inspect}" if result.any?
puts

# Example 2: AttributedString creation and usage
puts "2. AttributedString Objects"
puts "-" * 40

# Create an attributed string manually
attr_string = Imessage::Db::TypedStream::AttributedString.new(
  "This is bold and italic text",
  {
    "NSFont" => "Helvetica-BoldItalic",
    "NSColor" => "red",
    "NSLink" => "https://example.com"
  }
)

puts "String content: #{attr_string.plain_text}"
puts "Has attributes: #{attr_string.has_attributes?}"
puts "Attributes: #{attr_string.attributes}"
puts "Hash representation:"
pp attr_string.to_h
puts

# Example 3: Message integration
puts "3. Message Model Integration"
puts "-" * 40

# Create a sample message with attributed content
message = Imessage::Db::Message.new(
  text: "Fallback text",
  attributedBody: "some_binary_data"
)

puts "Message text: #{message.text}"
puts "Has attributed text: #{message.has_attributed_text?}"
puts "Content (best available): #{message.content}"
puts "Has formatting: #{message.has_formatting?}"

# Mock some formatting for demonstration
def message.text_attributes
  {
    "NSFont" => "Helvetica-Bold",
    "NSColor" => "blue",
    "NSLink" => "https://apple.com"
  }
end

puts "Text attributes: #{message.text_attributes}"
puts "Has bold text: #{message.has_bold_text?}"
puts "Has italic text: #{message.has_italic_text?}"
puts "Has links: #{message.has_links?}"
puts "Has formatting: #{message.has_formatting?}"
puts

# Example 4: Error handling
puts "4. Error Handling & Edge Cases"
puts "-" * 40

test_cases = [
  {name: "Empty data", data: ""},
  {name: "Nil data", data: nil},
  {name: "Invalid data", data: "not_typedstream_data"},
  {name: "Partial header", data: "\x04\x00\x00"}
]

test_cases.each do |test_case|
  puts "Testing #{test_case[:name]}:"

  # Decoder should handle errors gracefully
  result = Imessage::Db::TypedStream::Parser.decode(test_case[:data])
  attr_result = Imessage::Db::TypedStream::Parser.parse_attributed_string(test_case[:data])

  puts "  Decode result: #{result.class} (#{result.length} objects)" if result.is_a?(Array)
  puts "  AttributedString result: #{attr_result.class}"
  puts
end

# Example 5: Message scopes
puts "5. New Message Scopes"
puts "-" * 40

puts "Available scopes for finding messages with attributed text:"
puts "- Message.with_attributed_text"
puts "- Message.with_formatting (alias)"
puts

if Imessage::Db.full_disk_access?
  puts "Full Disk Access available - you can query real Messages data:"
  puts "  Imessage::Db::Message.with_attributed_text.limit(5)"
  puts "  Imessage::Db::Message.recent.with_formatting.each { |m| puts m.content }"
else
  puts "Full Disk Access not available - enable in System Settings to query real data"
end

puts
puts "=== TypedStream Integration Complete ==="
puts "This implementation provides:"
puts "✓ Binary typedstream format decoding"
puts "✓ AttributedString object modeling"
puts "✓ Message model integration"
puts "✓ Graceful error handling"
puts "✓ Rich text formatting detection"
puts "✓ ActiveRecord scopes for querying"
