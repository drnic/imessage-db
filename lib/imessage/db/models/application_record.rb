# frozen_string_literal: true

module Imessage
  module Db
    class ApplicationRecord < ActiveRecord::Base
      self.abstract_class = true

      # Establish a completely separate connection pool for iMessage models
      # Use a class method to ensure the connection is established when the class is loaded
      def self.establish_imessage_connection
        establish_connection(
          adapter: "sqlite3",
          database: Imessage::Db.chat_db_path,
          readonly: true,
          pool: 5,
          timeout: 5000
        )
      end

      # Establish connection when the class loads
      establish_imessage_connection
    end
  end
end
