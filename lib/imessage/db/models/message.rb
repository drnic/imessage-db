# frozen_string_literal: true

module Imessage
  module Db
    class Message < ApplicationRecord
      self.table_name = "message"
      self.primary_key = "ROWID"
      self.inheritance_column = nil # Disable single-table inheritance

      # Associations
      belongs_to :handle, foreign_key: "handle_id", primary_key: "ROWID", optional: true
      has_many :chat_message_joins, class_name: "ChatMessage", foreign_key: "message_id", primary_key: "ROWID"
      has_many :chats, through: :chat_message_joins, foreign_key: "message_id", primary_key: "ROWID"
      has_many :message_attachment_joins, class_name: "MessageAttachment", foreign_key: "message_id", primary_key: "ROWID"
      has_many :attachments, through: :message_attachment_joins, foreign_key: "message_id", primary_key: "ROWID"

      # Convert Apple nanosecond timestamps to Ruby Time objects
      def sent_at
        Imessage::Db.apple_time_to_ruby(date)
      end

      def delivered_at
        Imessage::Db.apple_time_to_ruby(date_delivered)
      end

      def read_at
        Imessage::Db.apple_time_to_ruby(date_read)
      end

      # Scopes
      scope :recent, -> { order(date: :desc) }
      scope :from_me, -> { where(is_from_me: 1) }
      scope :to_me, -> { where(is_from_me: 0) }
      scope :delivered, -> { where(is_delivered: 1) }
      scope :read, -> { where(is_read: 1) }
      scope :with_text, -> { where.not(text: [nil, ""]) }
      scope :with_attachments, -> { where(cache_has_attachments: 1) }

      # Service types
      scope :imessage, -> { where(service: "iMessage") }
      scope :sms, -> { where(service: "SMS") }

      # Find messages in a specific chat
      scope :in_chat, ->(chat) {
        return none unless chat

        chat_id = chat.is_a?(Chat) ? chat.ROWID : chat
        joins(:chat_message_joins).where(chat_message_join: {chat_id: chat_id})
      }

      # Convenience methods
      def from_me?
        is_from_me == 1
      end

      def to_me?
        is_from_me == 0
      end

      def delivered?
        is_delivered == 1
      end

      def read?
        is_read == 1
      end

      def has_attachments?
        cache_has_attachments == 1
      end

      def imessage?
        service == "iMessage"
      end

      def sms?
        service == "SMS"
      end

      def has_error?
        !error.nil? && error != 0
      end

      # Check if this is a tapback/reaction
      def tapback?
        !associated_message_guid.nil?
      end

      def reaction?
        tapback?
      end
    end
  end
end
