# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Testing
- `rake test` or `bundle exec rake test` - Run the full Minitest test suite (22 tests with 85 assertions)
- `ruby test/models/test_message.rb` - Run specific test file
- `bin/console` - Start IRB console with gem loaded for interactive testing

### Setup
- `bin/setup` - Install dependencies with bundler
- `bundle install` - Install gem dependencies
- `bundle exec rake install` - Install gem locally for testing

### Gem Management  
- `bundle exec rake build` - Build the gem package
- `bundle exec rake release` - Release new version (updates version, creates git tag, publishes to RubyGems)

## Architecture Overview

This is a Rails-compatible RubyGem that provides ActiveRecord models for reading macOS Messages database (`~/Library/Messages/chat.db`). The gem is structured as a Rails Engine for easy integration.

### Core Components

**Main Entry Point**: `lib/imessage/db.rb`
- Defines the main module with utilities like Apple epoch time conversion
- Provides `full_disk_access?` check for macOS permissions
- Requires all model files and database connection logic

**Rails Engine**: `lib/imessage/db/engine.rb`
- Rails Engine for autoloading models in Rails apps
- Configured for RSpec testing and FactoryBot fixtures
- Isolates namespace to prevent conflicts

**Database Connection**: `lib/imessage/db/database.rb`
- Manages read-only connection to `~/Library/Messages/chat.db`
- Handles Full Disk Access permission detection
- Isolates database connections from existing Rails configurations

**Models**: `lib/imessage/db/models/`
- `ApplicationRecord` - Base class for all models
- `Message` - Core model with Apple timestamp conversion, scopes, and convenience methods
- Future models: `Handle`, `Chat`, `Attachment`, and join models

### Key Features

**Apple Time Conversion**: Converts Apple's nanosecond epoch (since 2001-01-01) to Ruby Time objects using `Imessage::Db.apple_time_to_ruby()`

**Message Model Capabilities**:
- Convenience methods: `from_me?`, `imessage?`, `sms?`, `tapback?`
- Time accessors: `sent_at`, `delivered_at`, `read_at` 
- Comprehensive scopes: `recent`, `from_me`, `to_me`, `with_text`, `imessage`, `sms`

**Full Disk Access Integration**: Checks macOS permissions and provides helpful error messages when access is unavailable

### Testing Strategy

Uses Minitest with a comprehensive test suite that:
- Tests Apple epoch time conversion accuracy
- Validates all Message model methods and scopes
- Runs integration tests against real Messages database (when Full Disk Access enabled)
- Gracefully skips database-dependent tests when permissions unavailable
- Provides helpful error messages for setup requirements

### Development Notes

- **Read-only database access**: Never modifies Messages database
- **macOS only**: Requires `~/Library/Messages/chat.db` 
- **Full Disk Access required**: Must be enabled in macOS System Settings
- **Single-table inheritance disabled**: Handles `type` column conflicts in Messages schema
- **Rails Engine structure**: Enables easy integration with Rails applications