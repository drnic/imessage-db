# 📄 PRD: `imessage-db` RubyGem

## 1. Overview

`imessage-db` is a RubyGem that provides **Rails-friendly ActiveRecord models and utilities** for working with the macOS Messages app’s database (`~/Library/Messages/chat.db`).  

The gem will let developers:
- Read **chats**, **messages**, **handles** (contacts), and **attachments** directly from `chat.db`.
- Query and analyze conversation histories with ActiveRecord syntax inside Rails.
- Build Rails applications (or admin panels) that surface iMessage/SMS data locally.
- Run tests and demos that confirm correct permissions are set (Full Disk Access).

**Important note:**  
This gem is **not for App Store distribution** and is **single-user / local only**, since it requires Full Disk Access on macOS.  

---

## 2. Goals & Features

### Core Features
1. **ActiveRecord models** for main tables:
   - `Message`
   - `Handle`
   - `Chat`
   - `Attachment`
   - Join models (`ChatMessage`, `ChatHandle`, `MessageAttachment`).
2. **Associations**:
   - `Chat has_many :messages`
   - `Chat has_many :handles`
   - `Message belongs_to :chat` (through join)
   - `Message belongs_to :handle`
   - `Message has_many :attachments`
3. **Time conversion helpers**:
   - Convert Apple nanosecond epoch to Ruby `Time`.
   - Expose friendly scopes (`Message.recent`, `Chat.recent`).
4. **Scopes and Queries**:
   - `Chat.with_participant("+614…")`
   - `Message.in_chat(chat).last(50)`
   - `Attachment.for_message(message)`
5. **Setup utilities**:
   - Check that Full Disk Access is enabled.
   - Helpful error messages if DB cannot be read.
6. **Rails integration**:
   - Provide a Railtie to autoload models.
   - Provide a generator to copy over initializers/config.

### Stretch Features
- Export helpers (JSON/CSV for messages).
- Prebuilt dashboards (optional) using ActiveAdmin or Rails Admin.
- Support for detecting **tapbacks / reactions** (via `associated_message_guid`).
- Support for grouping attachments by type (images, videos, files).

---

## 3. Non-Goals
- Sending messages (covered by the existing [`imessage` gem](https://github.com/linjunpop/imessage)).
- Modifying the database (insert/update/delete).
- iOS support (only macOS has a readable SQLite `chat.db`).

---

## 4. Technical Requirements

### Database Schema (simplified)
**`message`**
- `ROWID` (PK)
- `handle_id` (FK → handle)
- `text` (TEXT)
- `service` (TEXT: “iMessage” / “SMS”)
- `date` (INTEGER, ns since 2001-01-01)
- `date_delivered`, `date_read`
- `is_from_me` (BOOLEAN)
- `is_delivered` (BOOLEAN)
- `is_read` (BOOLEAN)
- `error` (INTEGER)
- `associated_message_guid` (TEXT, tapbacks/replies)
- `cache_has_attachments` (BOOLEAN)

**`handle`**
- `ROWID` (PK)
- `id` (TEXT: phone/email)
- `country`
- `service`

**`chat`**
- `ROWID` (PK)
- `guid` (TEXT)
- `chat_identifier` (TEXT)
- `service_name`
- `display_name`

**Join tables**
- `chat_handle_join` (`chat_id`, `handle_id`)
- `chat_message_join` (`chat_id`, `message_id`)
- `message_attachment_join` (`message_id`, `attachment_id`)

**`attachment`**
- `ROWID` (PK)
- `filename` (TEXT, filesystem path)
- `mime_type`
- `transfer_name`
- `total_bytes`

---

## 5. Setup Requirements

### Full Disk Access Setup
- **Documentation** must explain:
  - Why Full Disk Access is needed (`~/Library/Messages/chat.db` is protected by TCC).
  - How to add Terminal, iTerm, or the Rails app itself in:  
    `System Settings → Privacy & Security → Full Disk Access`.
  - How to verify with:
    ```bash
    sqlite3 ~/Library/Messages/chat.db ".tables"
    ```
- Provide a Rails generator: `rails g imessage_db:install` that prints setup instructions.

---

## 6. Developer Experience

### Installation
```ruby
# Gemfile
gem "imessage-db"
```

### Example usage
```ruby
# Get last 10 chats
Chat.recent.limit(10).each do |chat|
  puts "Chat: #{chat.title}"
  chat.messages.last(5).each do |msg|
    who = msg.is_from_me? ? "me" : msg.handle&.id
    puts "[#{msg.sent_at}] #{who}: #{msg.text}"
  end
end
```

### Generators
- `rails g imessage_db:install` → adds initializer, docs, migration stubs (if needed for custom tables).
- `rails g imessage_db:models` → copies ActiveRecord models into `app/models`.

---

## 7. Testing

### Unit Tests
- Ensure each ActiveRecord model maps to DB correctly.
- Validate associations (chat ↔ message ↔ handle).
- Validate Apple epoch → Time conversion.

### Integration Tests
- Query last 5 messages in a chat and assert ordering.
- Query chat participants.
- Fetch attachments and confirm file paths.

### Current Test Implementation ✅
- **22 Minitest tests** with 85 assertions covering all functionality
- **Unit tests** for Apple epoch time conversion, model methods, scopes
- **Integration tests** that connect to real Messages database (when Full Disk Access enabled)
- **Graceful skipping** when Full Disk Access unavailable with helpful messages
- **Full test coverage** for `Message` model and core utilities

### Future Test Enhancements
- Provide sample SQLite `chat.db` (redacted) for CI
- Allow devs to run `IMESSAGE_DB_TEST_PATH=/tmp/chat.db bundle exec rake test`
- Add tests for additional models (`Handle`, `Chat`, `Attachment`) as they're implemented

---

## 8. Progress & Deliverables

### ✅ **Completed (Phase 1)**
- [x] **Rails Engine Foundation**: Set up Rails engine structure with proper autoloading and configuration
- [x] **Message ActiveRecord Model**: Core `Message` model with Apple epoch time conversion
  - Apple nanosecond timestamp → Ruby `Time` conversion helpers (`sent_at`, `delivered_at`, `read_at`)
  - Convenience methods (`from_me?`, `to_me?`, `imessage?`, `sms?`, `tapback?`, `reaction?`)
  - Comprehensive scopes (`recent`, `from_me`, `to_me`, `with_text`, `imessage`, `sms`, etc.)
  - Single-table inheritance disabled to handle `type` column conflict
- [x] **Database Connection Management**: Secure connection handling for `~/Library/Messages/chat.db`
  - Full Disk Access detection with helpful error messages
  - Read-only database connections with automatic cleanup
  - Connection isolation to preserve existing Rails database configurations
- [x] **Comprehensive Minitest Test Suite**: 22 tests with 85 assertions covering:
  - Apple epoch time conversion accuracy
  - Message model functionality and convenience methods
  - Database connectivity (when Full Disk Access enabled)
  - All scopes and filtering methods
  - Integration tests with real Messages database
- [x] **Working Example Script**: Demonstrates real usage with actual Messages data
  - Database statistics (message counts, service breakdowns)
  - Recent message display with proper formatting
  - Time conversion and service type detection
- [x] **Full Disk Access Integration**: Proper permission handling and user guidance

### 🚧 **Next Phase (Remaining Deliverables)**
- [ ] **Additional ActiveRecord Models**:
  - `Handle` model for contacts (phone numbers, emails)
  - `Chat` model for conversations
  - `Attachment` model for files, images, videos
  - Join models (`ChatMessage`, `ChatHandle`, `MessageAttachment`)
- [ ] **Model Associations**: Complete ActiveRecord relationships between all models
- [ ] **Extended Scopes & Queries**: Chat-specific and attachment-specific queries
- [ ] **Rails Generators**: 
  - `rails g imessage_db:install` for setup instructions
  - `rails g imessage_db:models` for copying models
- [ ] **Documentation**: 
  - README with setup guide, Full Disk Access instructions
  - Example Rails console walkthrough
  - API documentation for all models and methods
- [ ] **RubyGem Publication**: Package and publish to RubyGems.org
- [ ] **Advanced Features**:
  - Export helpers (JSON/CSV)
  - Schema version detection for macOS compatibility
  - Enhanced attachment grouping and filtering

---

## 9. Risks & Caveats

- Schema differences across macOS versions — must detect missing columns and degrade gracefully.
- Privacy & security: explicit warning that this gem is for **personal / internal use only**.
- No write support; read-only queries enforced.
