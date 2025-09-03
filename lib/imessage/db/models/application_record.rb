# frozen_string_literal: true

module Imessage
  module Db
    class ApplicationRecord < ActiveRecord::Base
      self.abstract_class = true
      
      class << self
        # Override connection to establish Messages database connection lazily
        def connection
          unless @messages_db_connected
            establish_connection(
              adapter: 'sqlite3',
              database: Imessage::Db.chat_db_path,
              readonly: true,
              pool: 5,
              timeout: 5000
            )
            @messages_db_connected = true
          end
          super
        end
      end
    end
  end
end
