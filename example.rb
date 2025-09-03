#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "lib/imessage/db"

puts "🔍 iMessage Database Reader Example"
puts "=" * 40

# Check if Full Disk Access is available
unless Imessage::Db.full_disk_access?
  puts "❌ Full Disk Access is not available."
  puts "   Please enable it in System Settings > Privacy & Security > Full Disk Access"
  puts "   Add your terminal application to the list and restart."
  exit 1
end

puts "✅ Full Disk Access is available!"
puts "📍 Database location: #{Imessage::Db.chat_db_path}"
puts

begin
  # Connect to the Messages database
  Imessage::Db::Database.establish_connection!
  puts "✅ Successfully connected to Messages database"
  
  # Get some basic statistics
  total_messages = Imessage::Db::Message.count
  puts "📊 Total messages in database: #{total_messages}"
  
  from_me_count = Imessage::Db::Message.from_me.count
  to_me_count = Imessage::Db::Message.to_me.count
  puts "📤 Messages from me: #{from_me_count}"
  puts "📥 Messages to me: #{to_me_count}"
  
  imessage_count = Imessage::Db::Message.imessage.count
  sms_count = Imessage::Db::Message.sms.count
  puts "💬 iMessages: #{imessage_count}"
  puts "📱 SMS messages: #{sms_count}"
  
  puts "\n📝 Recent Messages (last 5):"
  puts "-" * 40
  
  # Show last 5 messages with text
  Imessage::Db::Message.with_text.recent.limit(5).each do |message|
    direction = message.from_me? ? "➡️" : "⬅️"
    service = message.imessage? ? "iMessage" : "SMS"
    text = message.text&.truncate(60)
    time = message.sent_at&.strftime("%Y-%m-%d %H:%M:%S") || "Unknown time"
    
    puts "#{direction} [#{service}] #{time}"
    puts "   #{text}"
    puts
  end
  
rescue Imessage::Db::Error => e
  puts "❌ Error: #{e.message}"
rescue => e
  puts "❌ Unexpected error: #{e.message}"
ensure
  ActiveRecord::Base.remove_connection if ActiveRecord::Base.connected?
end

puts "🎉 Example completed!"