# 📱 imessage-db

A RubyGem that provides **Rails-friendly ActiveRecord models** for reading your macOS Messages app database. Query your iMessage and SMS conversations with familiar ActiveRecord syntax!

[![Ruby](https://img.shields.io/badge/ruby-%23CC342D.svg?style=for-the-badge&logo=ruby&logoColor=white)](https://ruby-lang.org)
[![Rails](https://img.shields.io/badge/rails-%23CC0000.svg?style=for-the-badge&logo=ruby-on-rails&logoColor=white)](https://rubyonrails.org)

## ✨ What This Gem Does

`imessage-db` lets you access your macOS Messages database (`~/Library/Messages/chat.db`) through ActiveRecord models, making it easy to:

- 📨 **Read messages** with proper time conversion from Apple's epoch format
- 🎨 **Access rich formatting** - bold, italic, links, and attributed text from iMessages
- 🔍 **Query conversations** using ActiveRecord scopes and associations
- 📊 **Analyze messaging patterns** and conversation history with formatting insights
- 🛠️ **Build Rails apps** that surface your iMessage/SMS data locally
- ⚡ **Run console commands** to explore your message data interactively

> **Important**: This gem is for **personal/local use only** and requires Full Disk Access. It's **not suitable for App Store distribution**.

## 🚀 Current Features

### ✅ What's Implemented
- **All Core Models**: `Message`, `Chat`, `Handle`, `Attachment` with full associations
- **Join Models**: `ChatMessage`, `ChatHandle`, `MessageAttachment` associations
- **Apple Time Conversion**: Automatic conversion from Apple epoch to Ruby Time
- **TypedStream Decoder**: Full support for Apple's binary attributed string format
- **Rich Text Support**: Access formatted text, bold, italic, links in iMessages
- **Database Connection**: Secure, read-only access with permission detection
- **Extended Scopes**: Advanced querying with `Chat.with_participant`, `Message.in_chat`, etc.
- **Comprehensive Testing**: 182 tests with 462 assertions including HTML/Markdown conversion
- **Rails Engine**: Drop-in compatibility with Rails applications

### 🔧 Core Message Capabilities
```ruby
# Time helpers (converts Apple epoch automatically)
message.sent_at      # => 2024-01-15 14:30:25 -0800
message.delivered_at # => 2024-01-15 14:30:26 -0800
message.read_at      # => 2024-01-15 14:32:10 -0800

# Convenience methods
message.from_me?     # => true/false
message.imessage?    # => true (blue bubble)
message.sms?         # => true (green bubble)
message.tapback?     # => true (reactions like ❤️, 👍, etc)

# Rich text and formatting support (NEW!)
message.content              # => Best available text (attributed or plain)
message.attributed_text      # => Rich text content from attributedBody
message.has_formatting?      # => true if message has rich formatting
message.has_bold_text?       # => true if contains bold text
message.has_italic_text?     # => true if contains italic text
message.has_links?           # => true if contains links

# HTML and Markdown conversion (NEW!)
message.to_html              # => "<strong>Bold text</strong>"
message.to_markdown          # => "**Bold text**"
message.content_as(:html)    # => HTML with custom options
message.content_as(:markdown) # => Markdown format

# Rich scoping
Message.recent.limit(10)           # Last 10 messages
Message.from_me.imessage          # Your iMessages
Message.to_me.sms                 # SMS you received
Message.with_text                 # Messages with text content
Message.with_attributed_text      # Messages with rich formatting (NEW!)
Message.with_formatting           # Alias for with_attributed_text (NEW!)
Message.in_chat(chat)             # Messages in specific chat
```

## 🚄 Rails Integration

The gem works seamlessly with Rails applications, maintaining its own database connection separate from your app's database:

```ruby
# Gemfile
gem 'imessage-db'
```

```ruby
# app/controllers/messages_controller.rb
class MessagesController < ApplicationController
  def index
    @messages = Imessage::Db::Message.recent.limit(50)
    @stats = {
      total: Imessage::Db::Message.count,
      imessage: Imessage::Db::Message.imessage.count,
      sms: Imessage::Db::Message.sms.count,
      formatted: Imessage::Db::Message.with_formatting.count  # NEW!
    }
  end

  def show
    @chat = Imessage::Db::Chat.find(params[:id])
    @messages = Imessage::Db::Message.in_chat(@chat).recent
    @participants = @chat.handles
    
    # Respond with different formats (NEW!)
    respond_to do |format|
      format.html  # Regular view
      format.json { render json: @messages.map(&:to_html) }  # HTML content
      format.text { render plain: @messages.map(&:to_text).join("\n") }
    end
  end

  def export
    # Export messages as Markdown (NEW!)
    @messages = Imessage::Db::Message.recent.limit(100)
    markdown_content = @messages.map(&:to_markdown).join("\n\n")
    
    send_data markdown_content, 
              filename: "messages_export.md", 
              type: "text/markdown"
  end
end
```

**No configuration needed!** The gem:
- ✅ Automatically connects to Messages database when first accessed
- ✅ Maintains separate connection pool from your app's database
- ✅ Works alongside PostgreSQL, MySQL, or any Rails database
- ✅ All models are namespaced under `Imessage::Db::`
- ✅ Read-only access ensures your Messages are never modified
- ✅ Robust TypedStream decoder with infinite loop protection

Just add the gem and start querying! See [Full Disk Access Setup](#-full-disk-access-setup-required) below for permissions.

### Rails View Integration (NEW!)
```erb
<!-- app/views/messages/show.html.erb -->
<div class="message-thread">
  <% @messages.each do |message| %>
    <div class="message <%= 'from-me' if message.from_me? %>">
      <div class="message-content">
        <% if message.has_formatting? %>
          <!-- Render rich HTML with secure link attributes -->
          <%= raw message.to_html(link_attributes: { 
                target: "_blank", 
                rel: "noopener nofollow",
                class: "message-link"
              }) %>
          <span class="formatting-badge">📝 Rich Text</span>
        <% else %>
          <!-- Render plain text (automatically HTML-escaped) -->
          <%= raw message.to_html %>
        <% end %>
      </div>
      
      <div class="message-meta">
        <span class="service-badge <%= message.service.downcase %>">
          <%= message.service %>
        </span>
        <time><%= message.sent_at %></time>
      </div>
    </div>
  <% end %>
</div>

<!-- Export buttons -->
<div class="export-actions">
  <%= link_to "Export as Markdown", export_path(format: :md), 
              class: "btn btn-outline" %>
  <%= link_to "Export as HTML", export_path(format: :html), 
              class: "btn btn-outline" %>
</div>
```

## 📝 Rich Text & Attributed Strings (NEW!)

The gem now includes a complete **Apple TypedStream decoder** for accessing rich text formatting in iMessages:

### ✨ Formatted Text Support
```ruby
# Access rich text content with fallback to plain text
message = Imessage::Db::Message.find(12345)
puts message.content  # Returns best available content

# Check for formatting
if message.has_formatting?
  puts "📝 Message has rich formatting!"
  puts "Bold: #{message.has_bold_text?}"
  puts "Italic: #{message.has_italic_text?}"  
  puts "Links: #{message.has_links?}"
end

# Access the full attributed string object
if attr_string = message.attributed_string
  puts "Text: #{attr_string.plain_text}"
  puts "Attributes: #{attr_string.attributes}"
end
```

### 🎨 HTML & Markdown Conversion (NEW!)
```ruby
# Convert messages to HTML for web display
message.to_html
# => "<strong>Bold text</strong> with <a href='https://example.com'>link</a>"

# Convert to Markdown for documentation
message.to_markdown  
# => "**Bold text** with [link](https://example.com)"

# Flexible format conversion
message.content_as(:html)       # HTML format
message.content_as(:markdown)   # Markdown format  
message.content_as(:text)       # Plain text

# HTML with custom link attributes for security
message.to_html(link_attributes: { target: "_blank", rel: "noopener" })
# => "<a href='...' target='_blank' rel='noopener'>link</a>"

# Direct AttributedString conversion
attr_string = message.attributed_string
attr_string.to_html             # Rich HTML
attr_string.to_markdown         # Markdown
attr_string.bold?               # Formatting checks
attr_string.link_url            # Extract link URLs
```

### 🔍 Query Messages with Formatting
```ruby
# Find messages with rich formatting
formatted_messages = Imessage::Db::Message.with_formatting.recent.limit(10)

# Or specifically messages with attributed text data
attributed_messages = Imessage::Db::Message.with_attributed_text

# Combine with other scopes
my_formatted_messages = Imessage::Db::Message.from_me
                                            .with_formatting
                                            .recent
```

### 🛡️ Robust & Safe
- **Infinite loop protection** - Handles malformed binary data safely
- **Graceful fallback** - Always returns plain text when rich text parsing fails
- **Production ready** - Comprehensive test coverage with edge cases
- **Memory efficient** - Processes attributed strings without hanging or crashes

### 🔧 Advanced TypedStream Usage
```ruby
# Direct TypedStream API access
binary_data = message.attributedBody
if objects = Imessage::Db::TypedStream::Parser.decode(binary_data)
  puts "Decoded #{objects.length} objects"
end

# Create AttributedString objects manually
attr_string = Imessage::Db::TypedStream::AttributedString.new(
  "Bold text with link",
  { "NSFont" => "Helvetica-Bold", "NSLink" => "https://example.com" }
)

puts attr_string.to_h  # => {string: "Bold text...", attributes: {...}}
```

## 📦 Installation

Add to your Gemfile:

```ruby
bundle add imessage-db --github drnic/imessage-db --branch develop
```

## 🔐 Full Disk Access Setup (Required)

**This gem requires Full Disk Access to read `~/Library/Messages/chat.db`.**

### Step 1: Enable Full Disk Access

1. Open **System Settings** → **Privacy & Security** → **Full Disk Access**
2. Click the **🔒 lock icon** and authenticate
3. Click **➕** and add your terminal application:
   - **Terminal.app** (`/System/Applications/Utilities/Terminal.app`)
   - **iTerm2** (`/Applications/iTerm.app`)
   - **VS Code** (`/Applications/Visual Studio Code.app`) if using integrated terminal
   - Your **Rails application** if deploying locally

If you're running tests or the demo script inside your editor, you'll need to grant your editor the permissions.

### Step 2: Verify Access

Test that you can access the database, and see how it finds your data:

```bash
bundle exec bin/demo
```

Also, access directly via `sqlite3`:

```bash
sqlite3 ~/Library/Messages/chat.db ".tables"
```

You should see tables like `message`, `chat`, `handle`, etc. If you get a permission error, Full Disk Access isn't properly configured.

### Step 3: Test the Gem

```ruby
require 'imessage/db'

# Check if Full Disk Access is working
if Imessage::Db.full_disk_access?
  puts "✅ Full Disk Access enabled!"
  puts "Total messages: #{Imessage::Db::Message.count}"
else
  puts "❌ Full Disk Access required - see setup instructions"
end
```

## 💻 Usage Examples

### Basic Console Exploration

```ruby
require 'imessage/db'

# Get database statistics
puts "Total messages: #{Imessage::Db::Message.count}"
puts "iMessages: #{Imessage::Db::Message.imessage.count}"
puts "SMS: #{Imessage::Db::Message.sms.count}"
puts "From me: #{Imessage::Db::Message.from_me.count}"

# Recent messages
puts "\n📱 Recent Messages:"
Imessage::Db::Message.recent.limit(5).each do |msg|
  direction = msg.from_me? ? "➡️ " : "⬅️ "
  service = msg.imessage? ? "iMessage" : "SMS"
  puts "#{direction}[#{msg.sent_at}] #{service}: #{msg.text}"
end
```

### Working with Chats and Participants

```ruby
# Find chats with a specific participant
chats = Imessage::Db::Chat.with_participant("+1234567890")
puts "Found #{chats.count} chats with this person"

# Get recent/active chats
recent_chats = Imessage::Db::Chat.recent.limit(10)
recent_chats.each do |chat|
  puts "#{chat.title}: #{chat.messages.count} messages"
end

# Messages in a specific chat
chat = Imessage::Db::Chat.first
messages = Imessage::Db::Message.in_chat(chat).recent.limit(20)
```

### Finding Specific Messages

```ruby
# Messages with text content
text_messages = Imessage::Db::Message.with_text
puts "Messages with text: #{text_messages.count}"

# Your sent iMessages vs SMS breakdown
my_imessages = Imessage::Db::Message.from_me.imessage.count
my_sms = Imessage::Db::Message.from_me.sms.count
puts "You sent #{my_imessages} iMessages and #{my_sms} SMS messages"
```

### Working with Attachments

```ruby
# Find different types of attachments
images = Imessage::Db::Attachment.images
videos = Imessage::Db::Attachment.videos
documents = Imessage::Db::Attachment.files  # Non-media files

# Attachments for a specific message
message = Imessage::Db::Message.with_attachments.first
attachments = Imessage::Db::Attachment.for_message(message)
attachments.each do |attachment|
  puts "#{attachment.file_type_description}: #{attachment.display_name} (#{attachment.file_size_mb} MB)"
end

# Messages with attachments
messages_with_files = Imessage::Db::Message.with_attachments
puts "Messages with attachments: #{messages_with_files.count}"
```


## 🧪 Run the Demo

Try the included example scripts:

```bash
# Clone the repo and run the main demo
git clone https://github.com/drnic/imessage-db.git
cd imessage-db
bundle install
bundle exec bin/demo

# Try the TypedStream decoder demo (NEW!)
ruby examples/typedstream_usage.rb

# Try the HTML/Markdown conversion demo (NEW!)
ruby examples/html_markdown_conversion.rb
```

Or in the console:

```bash
bin/console
```

This starts an IRB session with the gem loaded, perfect for interactive exploration of both basic messaging data and rich text formatting!

## 🧪 Running Tests

The gem includes a comprehensive test suite:

```bash
# Run all tests
rake test
# or
bundle exec rake test

# Run specific test file
ruby test/models/test_message.rb

# Start console for manual testing
bin/console
```

**Note**: Tests will automatically skip database-dependent tests if Full Disk Access isn't available, with helpful setup messages.

## 🗂️ Database Schema

The gem works with these main tables from `~/Library/Messages/chat.db`:

- **`message`** - Individual messages with text, timestamps, service type
  - `text` - Plain text content
  - `attributedBody` - Binary TypedStream data for rich formatting (NEW!)
- **`handle`** - Contacts (phone numbers, email addresses)  
- **`chat`** - Conversation threads
- **`attachment`** - Files, images, videos sent in messages
- **Join tables** - `chat_message_join`, `chat_handle_join`, `message_attachment_join`

### TypedStream Integration
The gem automatically decodes the binary `attributedBody` field using a custom Apple TypedStream parser, giving you access to:
- **Rich text formatting** (bold, italic, etc.)
- **Embedded links** and their attributes
- **Font and style information**
- **Graceful fallback** to plain text when parsing fails

## 🛣️ Roadmap

### ✅ Recently Completed
- **Apple TypedStream Decoder** - Full support for attributed strings and rich text formatting
- **Rich Text Methods** - `has_bold_text?`, `has_italic_text?`, `has_links?`, etc.
- **HTML & Markdown Conversion** - `to_html()`, `to_markdown()`, `content_as()` methods
- **Rails Integration** - Secure HTML rendering with custom link attributes
- **Infinite Loop Protection** - Robust handling of malformed binary data
- **Attributed Text Scopes** - `with_formatting` and `with_attributed_text` scopes

### 🚧 Coming Next
- **Rails Generators** - `rails g imessage_db:install` for easy setup
- **Export Helpers** - JSON/CSV export functionality with rich text preservation
- **Schema Version Detection** - Compatibility across macOS versions
- **Enhanced Attachment Handling** - Better media type detection

### 🎯 Future Features
- Enhanced conversation analytics with formatting insights
- Advanced TypedStream object support beyond attributed strings
- Rails admin panel integration with rich text display

## 🤝 Contributing

We'd love your help! Here's how to contribute:

### Development Setup

1. **Clone and setup**:
```bash
git clone https://github.com/drnic/imessage-db.git
cd imessage-db
bin/setup
```

2. **Enable Full Disk Access** for your terminal (see setup instructions above)

3. **Run tests** to verify everything works:
```bash
rake test
```

### Making Changes

1. **Create a feature branch**:
```bash
git checkout -b feature/your-feature-name
```

2. **Make your changes** and add tests

3. **Run the test suite**:
```bash
rake test
```

4. **Test manually with console**:
```bash
bin/console
# Try your changes interactively
```

5. **Submit a pull request** with a clear description

### What We Need Help With

- 📦 **Rails Generators**: Creating setup and model generators
- 📊 **Export Features**: JSON/CSV export functionality
- 🧪 **Tests**: Additional test coverage and edge cases
- 📚 **Documentation**: More usage examples and guides
- 🐛 **Bug fixes**: macOS compatibility across versions
- 🎨 **UI Components**: Optional Rails view helpers

### Code Style

- Follow existing patterns and conventions
- Add tests for new functionality
- Update documentation for public APIs
- Keep commits focused and atomic

## 📋 Requirements

- **Ruby** 3.0+ (tested with 3.4+)
- **macOS** with Messages app
- **Full Disk Access** enabled
- **ActiveRecord** 6.0+ (included with Rails)

## ⚠️ Important Notes

- **Read-only access** - This gem never modifies your Messages database
- **Personal use only** - Not suitable for App Store distribution
- **macOS only** - Requires `~/Library/Messages/chat.db`
- **Privacy first** - All data stays local on your machine

## 📄 License

This gem is available as open source under the terms of the MIT License.

## 🙋‍♀️ Support

- **Issues**: Report bugs on [GitHub Issues](https://github.com/drnic/imessage-db/issues)
- **Discussions**: Ask questions in [GitHub Discussions](https://github.com/drnic/imessage-db/discussions)
- **Contributions**: See our [Contributing Guide](#-contributing) above

---

**Happy message querying!** 📱✨
