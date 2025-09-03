#!/usr/bin/env ruby
# frozen_string_literal: true

require "sqlite3"
require "fileutils"

# Create a sample Messages database for testing
class TestDatabaseCreator
  TEST_DB_PATH = File.expand_path("../../../db/test.db", __FILE__)
  
  def self.create!
    new.create!
  end
  
  def create!
    FileUtils.rm_f(TEST_DB_PATH)
    
    db = SQLite3::Database.new(TEST_DB_PATH)
    
    create_schema(db)
    populate_fixtures(db)
    
    db.close
    puts "Created test database at: #{TEST_DB_PATH}"
  end
  
  private
  
  def create_schema(db)
    # Create handle table
    db.execute <<-SQL
      CREATE TABLE handle (
        ROWID INTEGER PRIMARY KEY AUTOINCREMENT,
        id TEXT,
        country TEXT,
        service TEXT
      );
    SQL
    
    # Create chat table  
    db.execute <<-SQL
      CREATE TABLE chat (
        ROWID INTEGER PRIMARY KEY AUTOINCREMENT,
        guid TEXT,
        chat_identifier TEXT,
        service_name TEXT,
        display_name TEXT
      );
    SQL
    
    # Create message table
    db.execute <<-SQL
      CREATE TABLE message (
        ROWID INTEGER PRIMARY KEY AUTOINCREMENT,
        handle_id INTEGER,
        text TEXT,
        service TEXT,
        date INTEGER,
        date_delivered INTEGER,
        date_read INTEGER,
        is_from_me INTEGER,
        is_delivered INTEGER,
        is_read INTEGER,
        error INTEGER,
        associated_message_guid TEXT,
        cache_has_attachments INTEGER,
        type INTEGER DEFAULT 0
      );
    SQL
    
    # Create attachment table
    db.execute <<-SQL
      CREATE TABLE attachment (
        ROWID INTEGER PRIMARY KEY AUTOINCREMENT,
        filename TEXT,
        mime_type TEXT,
        transfer_name TEXT,
        total_bytes INTEGER
      );
    SQL
    
    # Create join tables
    db.execute <<-SQL
      CREATE TABLE chat_handle_join (
        chat_id INTEGER,
        handle_id INTEGER,
        PRIMARY KEY (chat_id, handle_id)
      );
    SQL
    
    db.execute <<-SQL
      CREATE TABLE chat_message_join (
        chat_id INTEGER,
        message_id INTEGER,
        PRIMARY KEY (chat_id, message_id)
      );
    SQL
    
    db.execute <<-SQL
      CREATE TABLE message_attachment_join (
        message_id INTEGER,
        attachment_id INTEGER,
        PRIMARY KEY (message_id, attachment_id)
      );
    SQL
  end
  
  def populate_fixtures(db)
    # Apple epoch time (nanoseconds since 2001-01-01)
    base_time = 695000000000000000 # ~2023 in Apple epoch
    
    # Create handles (contacts)
    handles = [
      { id: "+14155551234", country: "us", service: "iMessage" },
      { id: "+14155555678", country: "us", service: "SMS" },
      { id: "alice@example.com", country: "us", service: "iMessage" },
      { id: "+61412345678", country: "au", service: "iMessage" },
      { id: "mom@family.com", country: "us", service: "iMessage" }
    ]
    
    handles.each_with_index do |handle, idx|
      db.execute("INSERT INTO handle (ROWID, id, country, service) VALUES (?, ?, ?, ?)",
                [idx + 1, handle[:id], handle[:country], handle[:service]])
    end
    
    # Create chats
    chats = [
      { guid: "iMessage;-;+14155551234", chat_identifier: "+14155551234", service_name: "iMessage", display_name: nil },
      { guid: "SMS;-;+14155555678", chat_identifier: "+14155555678", service_name: "SMS", display_name: nil },
      { guid: "iMessage;-;alice@example.com", chat_identifier: "alice@example.com", service_name: "iMessage", display_name: "Alice" },
      { guid: "iMessage;+;chat123456", chat_identifier: "chat123456", service_name: "iMessage", display_name: "Family Group" }
    ]
    
    chats.each_with_index do |chat, idx|
      db.execute("INSERT INTO chat (ROWID, guid, chat_identifier, service_name, display_name) VALUES (?, ?, ?, ?, ?)",
                [idx + 1, chat[:guid], chat[:chat_identifier], chat[:service_name], chat[:display_name]])
    end
    
    # Create messages
    messages = [
      # Individual chat with +14155551234
      { handle_id: 1, text: "Hey, how are you?", service: "iMessage", date: base_time, is_from_me: 0, is_delivered: 1, is_read: 1 },
      { handle_id: nil, text: "I'm doing great! Thanks for asking 😊", service: "iMessage", date: base_time + 300_000_000_000, is_from_me: 1, is_delivered: 1, is_read: 1 },
      { handle_id: 1, text: "That's awesome to hear!", service: "iMessage", date: base_time + 600_000_000_000, is_from_me: 0, is_delivered: 1, is_read: 1 },
      
      # SMS chat with +14155555678
      { handle_id: 2, text: "Can you pick up milk?", service: "SMS", date: base_time + 3600_000_000_000, is_from_me: 0, is_delivered: 1, is_read: 0 },
      { handle_id: nil, text: "Sure thing!", service: "SMS", date: base_time + 3900_000_000_000, is_from_me: 1, is_delivered: 1, is_read: 1 },
      
      # Chat with Alice
      { handle_id: 3, text: "Meeting at 3pm still on?", service: "iMessage", date: base_time + 7200_000_000_000, is_from_me: 0, is_delivered: 1, is_read: 1 },
      { handle_id: nil, text: "Yes! See you there", service: "iMessage", date: base_time + 7500_000_000_000, is_from_me: 1, is_delivered: 1, is_read: 1 },
      
      # Family group chat
      { handle_id: 5, text: "Who's bringing dessert to dinner Sunday?", service: "iMessage", date: base_time + 10800_000_000_000, is_from_me: 0, is_delivered: 1, is_read: 1 },
      { handle_id: nil, text: "I can bring apple pie!", service: "iMessage", date: base_time + 11100_000_000_000, is_from_me: 1, is_delivered: 1, is_read: 1 },
      { handle_id: 4, text: "Perfect! I'll make the main course 👩‍🍳", service: "iMessage", date: base_time + 11400_000_000_000, is_from_me: 0, is_delivered: 1, is_read: 1 },
      
      # Tapback example (reaction to apple pie message)
      { handle_id: 5, text: nil, service: "iMessage", date: base_time + 11200_000_000_000, is_from_me: 0, is_delivered: 1, is_read: 1, associated_message_guid: "msg-#{9}" },
      
      # Message with attachment
      { handle_id: 1, text: "Check out this photo!", service: "iMessage", date: base_time + 14400_000_000_000, is_from_me: 0, is_delivered: 1, is_read: 1, cache_has_attachments: 1 }
    ]
    
    messages.each_with_index do |msg, idx|
      params = [
        idx + 1, msg[:handle_id], msg[:text], msg[:service], msg[:date], 
        msg[:date_delivered] || 0, msg[:date_read] || 0, msg[:is_from_me], 
        msg[:is_delivered] || 0, msg[:is_read] || 0, msg[:error] || 0,
        msg[:associated_message_guid], msg[:cache_has_attachments] || 0
      ]
      
      db.execute(<<-SQL, params)
        INSERT INTO message (
          ROWID, handle_id, text, service, date, date_delivered, date_read,
          is_from_me, is_delivered, is_read, error, associated_message_guid, cache_has_attachments
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      SQL
    end
    
    # Create attachments
    attachments = [
      { filename: "/Users/test/Pictures/vacation.jpg", mime_type: "image/jpeg", transfer_name: "vacation.jpg", total_bytes: 2048576 },
      { filename: "/Users/test/Documents/contract.pdf", mime_type: "application/pdf", transfer_name: "contract.pdf", total_bytes: 1048576 }
    ]
    
    attachments.each_with_index do |att, idx|
      db.execute("INSERT INTO attachment (ROWID, filename, mime_type, transfer_name, total_bytes) VALUES (?, ?, ?, ?, ?)",
                [idx + 1, att[:filename], att[:mime_type], att[:transfer_name], att[:total_bytes]])
    end
    
    # Create join table relationships
    # Chat-Handle joins (who participates in each chat)
    chat_handle_joins = [
      [1, 1], # Chat 1 has handle 1
      [2, 2], # Chat 2 has handle 2  
      [3, 3], # Chat 3 has handle 3
      [4, 4], [4, 5] # Chat 4 (group) has handles 4 and 5
    ]
    
    chat_handle_joins.each do |chat_id, handle_id|
      db.execute("INSERT INTO chat_handle_join (chat_id, handle_id) VALUES (?, ?)", [chat_id, handle_id])
    end
    
    # Chat-Message joins (which messages belong to which chats)
    chat_message_joins = [
      [1, 1], [1, 2], [1, 3], [1, 12], # Messages 1-3,12 in chat 1
      [2, 4], [2, 5],                  # Messages 4-5 in chat 2
      [3, 6], [3, 7],                  # Messages 6-7 in chat 3
      [4, 8], [4, 9], [4, 10], [4, 11] # Messages 8-11 in chat 4
    ]
    
    chat_message_joins.each do |chat_id, message_id|
      db.execute("INSERT INTO chat_message_join (chat_id, message_id) VALUES (?, ?)", [chat_id, message_id])
    end
    
    # Message-Attachment joins
    message_attachment_joins = [
      [12, 1] # Message 12 has attachment 1
    ]
    
    message_attachment_joins.each do |message_id, attachment_id|
      db.execute("INSERT INTO message_attachment_join (message_id, attachment_id) VALUES (?, ?)", [message_id, attachment_id])
    end
  end
end

# Run if called directly
if __FILE__ == $0
  TestDatabaseCreator.create!
end