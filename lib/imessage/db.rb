# frozen_string_literal: true

require "active_record"

require_relative "db/version"
require_relative "db/database"
require_relative "db/models/application_record"
require_relative "db/models/message"
require_relative "db/models/handle"
require_relative "db/models/chat"
require_relative "db/models/attachment"
require_relative "db/models/chat_message"
require_relative "db/models/chat_handle"
require_relative "db/models/message_attachment"
require_relative "db/engine" if defined?(Rails::Engine)

module Imessage
  module Db
    class Error < StandardError; end
    
    # Apple's epoch starts at 2001-01-01 00:00:00 UTC
    APPLE_EPOCH = Time.new(2001, 1, 1, 0, 0, 0, "+00:00").freeze
    
    # Convert Apple nanosecond timestamp to Ruby Time
    def self.apple_time_to_ruby(apple_time)
      return nil if apple_time.nil? || apple_time.zero?
      
      APPLE_EPOCH + (apple_time / 1_000_000_000.0)
    end
    
    # Check if Full Disk Access is available
    def self.full_disk_access?
      chat_db_path = File.expand_path("~/Library/Messages/chat.db")
      File.readable?(chat_db_path)
    end
    
    # Get the path to the Messages database
    def self.chat_db_path
      File.expand_path("~/Library/Messages/chat.db")
    end
  end
end
