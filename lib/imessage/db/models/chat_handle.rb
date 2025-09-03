# frozen_string_literal: true

module Imessage
  module Db
    class ChatHandle < ApplicationRecord
      self.table_name = "chat_handle_join"
      self.primary_key = "chat_id" # Composite key, but ActiveRecord needs a primary key

      # Associations
      belongs_to :chat, foreign_key: "chat_id", primary_key: "ROWID"
      belongs_to :handle, foreign_key: "handle_id", primary_key: "ROWID"
    end
  end
end
