# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "minitest/autorun"
require "minitest/pride"
require "active_record"
require "imessage/db"

# Set up test database path
test_db_path = File.expand_path("../db/test.db", __dir__)

# Create test database if it doesn't exist
unless File.exist?(test_db_path)
  require_relative "fixtures/create_test_db"
  TestDatabaseCreator.create!
end

Imessage::Db.chat_db_path = test_db_path

# Establish database connection for tests
begin
  Imessage::Db::Database.establish_connection!
rescue Imessage::Db::Error => e
  puts "Warning: #{e.message}"
end
