# frozen_string_literal: true

require "sqlite3"

module Imessage
  module Db
    class Database
      class << self
        def establish_connection!
          db_path = Imessage::Db.chat_db_path

          # Skip Full Disk Access check for test database
          unless File.exist?(db_path)
            if db_path.include?("test.db")
              raise Imessage::Db::Error, "Test database not found at #{db_path}. Run 'ruby db/create_test_db.rb' to create it."
            else
              unless Imessage::Db.full_disk_access?
                raise Imessage::Db::Error, "Cannot access Messages database. Please enable Full Disk Access for your terminal or Rails app in System Settings > Privacy & Security > Full Disk Access"
              end
            end
          end

          # Use readonly only for the real Messages database, not test database
          connection_config = {
            adapter: "sqlite3",
            database: db_path
          }

          # Only apply readonly flag to the real Messages database
          unless db_path.include?("test.db")
            connection_config[:flags] = SQLite3::Constants::Open::READONLY
          end

          # Connect via ApplicationRecord to isolate from ActiveRecord::Base
          Imessage::Db::ApplicationRecord.establish_connection(connection_config)
        end

        def with_connection(&block)
          # Store the original connection
          original_connection = Imessage::Db::ApplicationRecord.connection_pool.spec if Imessage::Db::ApplicationRecord.connected?

          begin
            establish_connection!
            yield
          ensure
            # Restore the original connection if there was one
            if original_connection
              Imessage::Db::ApplicationRecord.establish_connection(original_connection.config)
            else
              Imessage::Db::ApplicationRecord.remove_connection
            end
          end
        end
      end
    end
  end
end
