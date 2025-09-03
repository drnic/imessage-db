#!/usr/bin/env ruby
# frozen_string_literal: true

# Example demonstrating HTML and Markdown conversion from iMessage attributed text

require_relative "../lib/imessage/db"

# Add string truncation helper for the demo
class String
  def truncate(length)
    if self.length > length
      "#{self[0, length - 3]}..."
    else
      self
    end
  end
end

puts "=== HTML & Markdown Conversion for iMessages ==="
puts

# Example 1: Creating attributed strings with different formatting
puts "1. AttributedString HTML/Markdown Conversion"
puts "-" * 50

examples = [
  {
    name: "Plain text",
    text: "Just plain text",
    attrs: {}
  },
  {
    name: "Bold text",
    text: "This is bold",
    attrs: {"NSFont" => "Helvetica-Bold"}
  },
  {
    name: "Italic text",
    text: "This is italic",
    attrs: {"NSFont" => "Helvetica-Italic"}
  },
  {
    name: "Link",
    text: "Click here",
    attrs: {"NSLink" => "https://apple.com"}
  },
  {
    name: "Colored text",
    text: "Red text",
    attrs: {"NSColor" => "red"}
  },
  {
    name: "Underlined text",
    text: "Underlined",
    attrs: {"NSUnderlineStyle" => "1"}
  },
  {
    name: "Bold + Link",
    text: "Bold link",
    attrs: {
      "NSFont" => "Helvetica-Bold",
      "NSLink" => "https://example.com"
    }
  },
  {
    name: "Bold + Italic + Color + Link",
    text: "Fully formatted",
    attrs: {
      "NSFont" => "Helvetica-BoldItalic",
      "NSColor" => "blue",
      "NSLink" => "https://github.com"
    }
  }
]

examples.each do |example|
  puts "#{example[:name]}:"

  attr_string = Imessage::Db::TypedStream::AttributedString.new(
    example[:text],
    example[:attrs]
  )

  puts "  Original: #{attr_string.plain_text}"
  puts "  HTML:     #{attr_string.to_html}"
  puts "  Markdown: #{attr_string.to_markdown}"

  # Show detected formatting
  formatting = []
  formatting << "bold" if attr_string.bold?
  formatting << "italic" if attr_string.italic?
  formatting << "link" if attr_string.link?
  formatting << "underlined" if attr_string.underlined?
  formatting << "colored" if attr_string.color

  unless formatting.empty?
    puts "  Detected: #{formatting.join(", ")}"
  end

  puts
end

# Example 2: Message model integration
puts "2. Message Model HTML/Markdown Methods"
puts "-" * 50

# Create mock messages with different content types
messages = [
  {
    desc: "Plain text message",
    msg: Imessage::Db::Message.new(text: "Hello world! <script>alert('xss')</script>", attributedBody: nil)
  },
  {
    desc: "Message with mock attributed text",
    msg: Imessage::Db::Message.new(text: "Fallback text", attributedBody: "mock_data")
  }
]

messages.each do |example|
  puts "#{example[:desc]}:"
  message = example[:msg]

  puts "  Original: #{message.text}"
  puts "  HTML:     #{message.to_html}"
  puts "  Markdown: #{message.to_markdown}"
  puts "  Plain:    #{message.to_text}"
  puts
end

# Example 3: content_as method for flexible formatting
puts "3. Flexible Format Conversion"
puts "-" * 50

message = Imessage::Db::Message.new(text: "Sample message with <HTML> & 'quotes'")

formats = [:html, :markdown, :text]
formats.each do |format|
  result = message.content_as(format)
  puts "#{format.to_s.upcase.ljust(8)}: #{result}"
end

# Example 4: HTML with custom link attributes
puts
puts "4. HTML with Custom Link Attributes"
puts "-" * 50

link_attr_string = Imessage::Db::TypedStream::AttributedString.new(
  "External link",
  {"NSLink" => "https://external-site.com"}
)

# Basic HTML
puts "Basic HTML:   #{link_attr_string.to_html}"

# HTML with custom link attributes
options = {
  link_attributes: {
    target: "_blank",
    rel: "noopener nofollow",
    class: "external-link"
  }
}
puts "Custom HTML:  #{link_attr_string.to_html(options)}"

# Example 5: Real message processing (if available)
puts
puts "5. Real Message Processing"
puts "-" * 50

if Imessage::Db.full_disk_access?
  puts "Processing recent messages with attributed text..."

  # Find messages with attributed text
  attributed_messages = Imessage::Db::Message.with_attributed_text.recent.limit(3)

  if attributed_messages.any?
    attributed_messages.each_with_index do |msg, i|
      puts "\nMessage #{i + 1}:"
      puts "  Service: #{msg.service}"
      puts "  From me: #{msg.from_me?}"
      puts "  Text:    #{msg.text&.truncate(60) || "(no text)"}"

      if msg.has_formatting?
        puts "  HTML:    #{msg.to_html.truncate(100)}"
        puts "  Markdown: #{msg.to_markdown.truncate(100)}"

        formatting_info = []
        formatting_info << "bold" if msg.has_bold_text?
        formatting_info << "italic" if msg.has_italic_text?
        formatting_info << "links" if msg.has_links?
        puts "  Formatting: #{formatting_info.join(", ")}"
      else
        puts "  No rich formatting detected"
      end
    end
  else
    puts "  No messages with attributed text found in recent messages"
  end

  # Show statistics
  total_attributed = Imessage::Db::Message.with_attributed_text.count
  total_messages = Imessage::Db::Message.count
  percentage = (total_messages > 0) ? (total_attributed.to_f / total_messages * 100).round(2) : 0

  puts "\nStatistics:"
  puts "  Total messages: #{total_messages}"
  puts "  With attributed text: #{total_attributed} (#{percentage}%)"

else
  puts "Full Disk Access required to process real messages"
  puts "Enable in System Settings → Privacy & Security → Full Disk Access"
end

# Example 6: Integration with Rails views
puts
puts "6. Rails Integration Example"
puts "-" * 50

puts <<~RAILS_EXAMPLE
  <!-- In your Rails view (app/views/messages/show.html.erb) -->
  <div class="message">
    <% if @message.has_formatting? %>
      <!-- Render rich HTML with custom link styling -->
      <%= raw @message.to_html(link_attributes: { target: "_blank", class: "message-link" }) %>
    <% else %>
      <!-- Plain text (already HTML-escaped) -->
      <%= raw @message.to_html %>
    <% end %>
  </div>

  <!-- For markdown rendering with a gem like redcarpet -->
  <div class="message-markdown">
    <%= markdown(@message.to_markdown) %>
  </div>

  <!-- Dynamic format selection -->
  <div class="message-content">
    <%= raw @message.content_as(params[:format] || :html) %>
  </div>
RAILS_EXAMPLE

puts
puts "=== HTML & Markdown Conversion Complete ==="
puts
puts "Key Features Demonstrated:"
puts "✓ HTML conversion with proper escaping and formatting"
puts "✓ Markdown conversion for documentation/export"
puts "✓ Flexible format selection with content_as()"
puts "✓ Custom link attributes for security (target, rel, etc.)"
puts "✓ Graceful fallback to plain text when no formatting"
puts "✓ Rails view integration patterns"
puts "✓ Rich formatting detection and statistics"
