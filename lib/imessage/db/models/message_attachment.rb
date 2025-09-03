# frozen_string_literal: true

module Imessage
  module Db
    class MessageAttachment < ApplicationRecord
      self.table_name = "message_attachment_join"
      self.primary_key = "message_id" # Composite key, but ActiveRecord needs a primary key

      # Associations
      belongs_to :message, foreign_key: "message_id", primary_key: "ROWID"
      belongs_to :attachment, foreign_key: "attachment_id", primary_key: "ROWID"
    end
  end
end