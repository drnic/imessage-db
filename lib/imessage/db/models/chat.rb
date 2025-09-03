# frozen_string_literal: true

module Imessage
  module Db
    class Chat < ApplicationRecord
      self.table_name = "chat"
      self.primary_key = "ROWID"

      # Associations
      has_many :chat_messages, primary_key: "ROWID"
      has_many :messages, through: :chat_messages, primary_key: "ROWID"
      has_many :chat_handles, primary_key: "ROWID"
      has_many :handles, through: :chat_handles, primary_key: "ROWID"

      # Scopes
      scope :by_service, ->(service) { where(service_name: service) }
      scope :imessage, -> { where(service_name: "iMessage") }
      scope :sms, -> { where(service_name: "SMS") }
      scope :group_chats, -> { where.not(display_name: [nil, ""]) }
      scope :direct_messages, -> { where(display_name: [nil, ""]) }
      scope :recent, -> { joins(:messages).group("chat.ROWID").order("MAX(message.date) DESC") }
      scope :active, -> { recent }

      # Find chats with a specific participant (phone or email)
      scope :with_participant, lambda { |identifier|
        return none if identifier.blank?

        # Normalize the identifier (remove non-digits from phone numbers)
        normalized = identifier.to_s.gsub(/[^\d@.]/, "")

        # Search in multiple formats
        joins(:handles).where(
          "handle.id LIKE ? OR handle.id LIKE ? OR handle.id LIKE ?",
          "%#{identifier}%",
          "%#{normalized}%",
          "+1#{normalized}"
        ).distinct
      }

      # Convenience methods
      def imessage?
        service_name == "iMessage"
      end

      def sms?
        service_name == "SMS"
      end

      def group_chat?
        display_name.present?
      end

      def direct_message?
        display_name.blank?
      end

      def title
        if group_chat?
          display_name
        else
          chat_identifier || "Unknown Chat"
        end
      end

      # Parse participants from chat_identifier for direct messages
      def participant_identifiers
        return [] unless chat_identifier

        # Chat identifiers are typically semicolon-separated for group chats
        # or single identifiers for direct messages
        chat_identifier.split(";").map(&:strip)
      end
    end
  end
end
