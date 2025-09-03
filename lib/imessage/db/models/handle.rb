# frozen_string_literal: true

module Imessage
  module Db
    class Handle < ApplicationRecord
      self.table_name = "handle"
      self.primary_key = "ROWID"

      # Associations
      has_many :messages, foreign_key: "handle_id", primary_key: "ROWID"
      has_many :chat_handle_joins, class_name: "ChatHandle", foreign_key: "handle_id", primary_key: "ROWID"
      has_many :chats, through: :chat_handle_joins, foreign_key: "handle_id", primary_key: "ROWID"

      # Scopes
      scope :by_service, ->(service) { where(service: service) }
      scope :imessage, -> { where(service: "iMessage") }
      scope :sms, -> { where(service: "SMS") }

      # Convenience methods
      def phone_number?
        id.to_s.match?(/^\+?\d+$/)
      end

      def email?
        id.to_s.include?("@")
      end

      def imessage?
        service == "iMessage"
      end

      def sms?
        service == "SMS"
      end

      def display_name
        phone_number? ? format_phone_number : id.to_s
      end

      private

      def format_phone_number
        # Basic phone number formatting - could be enhanced
        return id.to_s unless phone_number?

        # Remove country code prefix if present
        number = id.to_s.gsub(/^\+?1/, "")

        # Format as (XXX) XXX-XXXX if 10 digits
        if number.length == 10
          "(#{number[0..2]}) #{number[3..5]}-#{number[6..9]}"
        else
          id.to_s
        end
      end
    end
  end
end
