# frozen_string_literal: true

module Imessage
  module Db
    class Message < ApplicationRecord
      self.table_name = "message"
      self.primary_key = "ROWID"
      self.inheritance_column = nil # Disable single-table inheritance

      # Associations
      belongs_to :handle, primary_key: "ROWID", optional: true
      belongs_to :chat, primary_key: "ROWID"
      has_many :chat_messages, primary_key: "ROWID"
      has_many :chats, through: :chat_messages, primary_key: "ROWID"
      has_many :message_attachments, primary_key: "ROWID"
      has_many :attachments, through: :message_attachments, primary_key: "ROWID"

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

      # Attributed text scopes
      scope :with_attributed_text, -> { where.not(attributedBody: [nil, ""]) }
      scope :with_formatting, -> { with_attributed_text }

      # Find messages in a specific chat
      scope :in_chat, lambda { |chat|
        return none unless chat

        chat_id = chat.is_a?(Chat) ? chat.ROWID : chat
        joins(:chat_messages).where(chat_messages: {chat_id: chat_id})
      }

      # Convenience methods
      def from_me?
        is_from_me == 1
      end

      def to_me?
        is_from_me.zero?
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

      # TypedStream Integration for attributed string content

      # Parse attributed string from attributedBody field
      def attributed_text
        return nil unless attributedBody && !attributedBody.empty?

        begin
          # attributedBody contains typedstream binary data
          decoded = Imessage::Db::TypedStream::Parser.parse_attributed_string(attributedBody)
          return decoded.plain_text if decoded
        rescue
          # Fall back to plain text if parsing fails
        end

        text
      end

      # Get full attributed string object with formatting
      def attributed_string
        return nil unless attributedBody

        begin
          Imessage::Db::TypedStream::Parser.parse_attributed_string(attributedBody)
        rescue
          nil
        end
      end

      # Check if message has rich formatting
      def has_attributed_text?
        !attributedBody.nil? && attributedBody.length > 0
      end

      # Get the best available text content (attributed or plain)
      def content
        attributed_text || text
      end

      # Get formatting attributes if available
      def text_attributes
        attributed_string&.attributes || {}
      end

      # Check if message contains specific formatting
      def has_formatting?
        has_attributed_text? && !text_attributes.empty?
      end

      # Convenience methods for common formatting checks
      def has_bold_text?
        text_attributes.any? { |key, value| key.to_s =~ /bold/i || value.to_s =~ /bold/i }
      end

      def has_italic_text?
        text_attributes.any? { |key, value| key.to_s =~ /italic/i || value.to_s =~ /italic/i }
      end

      def has_links?
        text_attributes.any? { |key, value| key.to_s =~ /link|url/i || value.to_s =~ /link|url/i }
      end

      # HTML and Markdown conversion methods

      # Convert message content to HTML with optional link attributes
      def to_html(options = {})
        if attr_string = attributed_string
          attr_string.to_html(options)
        else
          # Fallback: HTML-escape plain text
          html_escape(text.to_s)
        end
      end

      # Convert message content to Markdown
      def to_markdown
        if attr_string = attributed_string
          attr_string.to_markdown
        else
          # Plain text is already valid Markdown
          text.to_s
        end
      end

      # Convert message content to plain text (for compatibility)
      def to_text
        content
      end

      # Get message content in specified format
      def content_as(format, options = {})
        case format.to_s.downcase
        when "html"
          to_html(options)
        when "markdown", "md"
          to_markdown
        when "text", "plain"
          to_text
        else
          raise ArgumentError, "Unknown format: #{format}. Supported formats: html, markdown, text"
        end
      end

      private

      def html_escape(text)
        return "" if text.nil?

        text.gsub("&", "&amp;")
          .gsub("<", "&lt;")
          .gsub(">", "&gt;")
          .gsub('"', "&quot;")
          .gsub("'", "&#39;")
      end
    end
  end
end
