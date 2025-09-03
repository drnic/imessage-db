# frozen_string_literal: true

module Imessage
  module Db
    class Attachment < ApplicationRecord
      self.table_name = "attachment"
      self.primary_key = "ROWID"

      # Associations
      has_many :message_attachment_joins, foreign_key: "attachment_id", primary_key: "ROWID"
      has_many :messages, through: :message_attachment_joins, foreign_key: "attachment_id", primary_key: "ROWID"

      # Scopes
      scope :images, -> { where("mime_type LIKE ?", "image/%") }
      scope :videos, -> { where("mime_type LIKE ?", "video/%") }
      scope :audio, -> { where("mime_type LIKE ?", "audio/%") }
      scope :documents, -> { where.not("mime_type LIKE ? OR mime_type LIKE ? OR mime_type LIKE ?", "image/%", "video/%", "audio/%") }
      scope :with_files, -> { where.not(filename: [nil, ""]) }

      # Convenience methods
      def image?
        mime_type&.start_with?("image/")
      end

      def video?
        mime_type&.start_with?("video/")
      end

      def audio?
        mime_type&.start_with?("audio/")
      end

      def document?
        !image? && !video? && !audio?
      end

      def file_exists?
        return false unless filename
        File.exist?(filename)
      end

      def file_extension
        return nil unless filename
        File.extname(filename).downcase.delete(".")
      end

      def display_name
        transfer_name.presence || File.basename(filename) if filename
      end

      def file_size_mb
        return nil unless total_bytes
        (total_bytes / 1024.0 / 1024.0).round(2)
      end

      def file_type_description
        case
        when image?
          "Image"
        when video?
          "Video"
        when audio?
          "Audio"
        when document?
          "Document"
        else
          "File"
        end
      end
    end
  end
end