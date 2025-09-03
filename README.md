# 📱 imessage-db

A RubyGem that provides **Rails-friendly ActiveRecord models** for reading your macOS Messages app database. Query your iMessage and SMS conversations with familiar ActiveRecord syntax!

[![Ruby](https://img.shields.io/badge/ruby-%23CC342D.svg?style=for-the-badge&logo=ruby&logoColor=white)](https://ruby-lang.org)
[![Rails](https://img.shields.io/badge/rails-%23CC0000.svg?style=for-the-badge&logo=ruby-on-rails&logoColor=white)](https://rubyonrails.org)

## ✨ What This Gem Does

`imessage-db` lets you access your macOS Messages database (`~/Library/Messages/chat.db`) through ActiveRecord models, making it easy to:

- 📨 **Read messages** with proper time conversion from Apple's epoch format
- 🔍 **Query conversations** using ActiveRecord scopes and associations
- 📊 **Analyze messaging patterns** and conversation history
- 🛠️ **Build Rails apps** that surface your iMessage/SMS data locally
- ⚡ **Run console commands** to explore your message data interactively

> **Important**: This gem is for **personal/local use only** and requires Full Disk Access. It's **not suitable for App Store distribution**.

## 🚀 Current Features

### ✅ What's Implemented
- **All Core Models**: `Message`, `Chat`, `Handle`, `Attachment` with full associations
- **Join Models**: `ChatMessage`, `ChatHandle`, `MessageAttachment` associations
- **Apple Time Conversion**: Automatic conversion from Apple epoch to Ruby Time
- **Database Connection**: Secure, read-only access with permission detection
- **Extended Scopes**: Advanced querying with `Chat.with_participant`, `Message.in_chat`, etc.
- **Comprehensive Testing**: 105 tests with 245 assertions
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

# Rich scoping
Message.recent.limit(10)           # Last 10 messages
Message.from_me.imessage          # Your iMessages
Message.to_me.sms                 # SMS you received
Message.with_text                 # Messages with text content
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
      sms: Imessage::Db::Message.sms.count
    }
  end

  def show
    @chat = Imessage::Db::Chat.find(params[:id])
    @messages = Imessage::Db::Message.in_chat(@chat).recent
    @participants = @chat.handles
  end
end
```

**No configuration needed!** The gem:
- ✅ Automatically connects to Messages database when first accessed
- ✅ Maintains separate connection pool from your app's database
- ✅ Works alongside PostgreSQL, MySQL, or any Rails database
- ✅ All models are namespaced under `Imessage::Db::`
- ✅ Read-only access ensures your Messages are never modified

Just add the gem and start querying! See [Full Disk Access Setup](#-full-disk-access-setup-required) below for permissions.

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

Try the included example script:

```bash
# Clone the repo and run the demo
git clone https://github.com/drnic/imessage-db.git
cd imessage-db
bundle install
bundle exec bin/demo
```

Or in the console:

```bash
bin/console
```

This starts an IRB session with the gem loaded, perfect for interactive exploration!

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
- **`handle`** - Contacts (phone numbers, email addresses)
- **`chat`** - Conversation threads
- **`attachment`** - Files, images, videos sent in messages
- **Join tables** - `chat_message_join`, `chat_handle_join`, `message_attachment_join`

## 🛣️ Roadmap

### 🚧 Coming Next
- **Rails Generators** - `rails g imessage_db:install` for easy setup
- **Export Helpers** - JSON/CSV export functionality
- **Schema Version Detection** - Compatibility across macOS versions
- **Enhanced Attachment Handling** - Better media type detection

### 🎯 Future Features
- Export helpers (JSON/CSV)
- Conversation analytics
- Tapback/reaction detection
- Rails admin panel integration

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
