# frozen_string_literal: true

module Imessage
  module Db
    class Database
      class << self
        def establish_connection!
          unless Imessage::Db.full_disk_access?
            raise Imessage::Db::Error, "Cannot access Messages database. Please enable Full Disk Access for your terminal or Rails app in System Settings > Privacy & Security > Full Disk Access"
          end

          ActiveRecord::Base.establish_connection(
            adapter: "sqlite3",
            database: Imessage::Db.chat_db_path,
            readonly: true
          )
        end

        def with_connection(&block)
          # Store the original connection
          original_connection = ActiveRecord::Base.connection_pool.spec if ActiveRecord::Base.connected?
          
          begin
            establish_connection!
            yield
          ensure
            # Restore the original connection if there was one
            if original_connection
              ActiveRecord::Base.establish_connection(original_connection.config)
            else
              ActiveRecord::Base.remove_connection
            end
          end
        end
      end
    end
  end
end