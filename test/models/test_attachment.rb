# frozen_string_literal: true

require "test_helper"

module Imessage::Db
  class TestAttachment < Minitest::Test
    def setup
      skip_unless_full_disk_access
      @attachment = Attachment.first
    end

    # Basic model tests
    def test_table_name
      assert_equal "attachment", Attachment.table_name
    end

    def test_primary_key
      assert_equal "ROWID", Attachment.primary_key
    end

    # Association tests
    def test_has_many_messages
      skip_unless_full_disk_access
      skip "No attachment found" unless @attachment

      assert_respond_to @attachment, :messages
      assert_kind_of ActiveRecord::Associations::CollectionProxy, @attachment.messages
    end

    # Scope tests
    def test_images_scope
      skip_unless_full_disk_access
      images = Attachment.images
      assert_kind_of ActiveRecord::Relation, images

      if images.any?
        assert images.first.mime_type.start_with?("image/")
      end
    end

    def test_videos_scope
      skip_unless_full_disk_access
      videos = Attachment.videos
      assert_kind_of ActiveRecord::Relation, videos

      if videos.any?
        assert videos.first.mime_type.start_with?("video/")
      end
    end

    def test_audio_scope
      skip_unless_full_disk_access
      audio_files = Attachment.audio
      assert_kind_of ActiveRecord::Relation, audio_files

      if audio_files.any?
        assert audio_files.first.mime_type.start_with?("audio/")
      end
    end

    def test_documents_scope
      skip_unless_full_disk_access
      documents = Attachment.documents
      assert_kind_of ActiveRecord::Relation, documents

      if documents.any?
        attachment = documents.first
        assert !attachment.mime_type.start_with?("image/")
        assert !attachment.mime_type.start_with?("video/")
        assert !attachment.mime_type.start_with?("audio/")
      end
    end

    def test_files_scope
      skip_unless_full_disk_access
      # files is an alias for documents
      files = Attachment.files
      documents = Attachment.documents

      assert_equal documents.count, files.count
      if files.any? && documents.any?
        assert_equal documents.pluck(:ROWID), files.pluck(:ROWID)
      end
    end

    def test_with_files_scope
      skip_unless_full_disk_access
      attachments_with_files = Attachment.with_files
      assert_kind_of ActiveRecord::Relation, attachments_with_files

      if attachments_with_files.any?
        refute_nil attachments_with_files.first.filename
        refute_empty attachments_with_files.first.filename
      end
    end

    def test_for_message_scope
      skip_unless_full_disk_access

      # Find a message with attachments
      message_with_attachments = Message.with_attachments.first
      skip "No messages with attachments found" unless message_with_attachments

      attachments = Attachment.for_message(message_with_attachments)
      assert_kind_of ActiveRecord::Relation, attachments

      if attachments.any?
        # Verify the attachment is actually associated with this message
        attachment = attachments.first
        message_ids = attachment.messages.pluck(:ROWID)
        assert_includes message_ids, message_with_attachments.ROWID
      end
    end

    def test_for_message_scope_with_id
      skip_unless_full_disk_access

      message_with_attachments = Message.with_attachments.first
      skip "No messages with attachments found" unless message_with_attachments

      # Test with message ID instead of object
      attachments = Attachment.for_message(message_with_attachments.ROWID)
      assert_kind_of ActiveRecord::Relation, attachments
    end

    def test_for_message_scope_with_nil
      attachments = Attachment.for_message(nil)
      assert_kind_of ActiveRecord::Relation, attachments
      assert_equal 0, attachments.count
    end

    # Convenience method tests
    def test_image_method
      skip_unless_full_disk_access
      skip "No attachment found" unless @attachment

      if @attachment.mime_type&.start_with?("image/")
        assert @attachment.image?
        assert !@attachment.video?
        assert !@attachment.audio?
        assert !@attachment.document?
      end
    end

    def test_video_method
      skip_unless_full_disk_access
      skip "No attachment found" unless @attachment

      if @attachment.mime_type&.start_with?("video/")
        assert @attachment.video?
        assert !@attachment.image?
        assert !@attachment.audio?
        assert !@attachment.document?
      end
    end

    def test_audio_method
      skip_unless_full_disk_access
      skip "No attachment found" unless @attachment

      if @attachment.mime_type&.start_with?("audio/")
        assert @attachment.audio?
        assert !@attachment.image?
        assert !@attachment.video?
        assert !@attachment.document?
      end
    end

    def test_document_method
      skip_unless_full_disk_access
      skip "No attachment found" unless @attachment

      if !@attachment.image? && !@attachment.video? && !@attachment.audio?
        assert @attachment.document?
      end
    end

    def test_file_exists_method
      skip_unless_full_disk_access
      skip "No attachment found" unless @attachment

      result = @attachment.file_exists?
      assert [true, false].include?(result)

      if @attachment.filename.nil?
        assert_equal false, result
      end
    end

    def test_file_extension
      skip_unless_full_disk_access
      skip "No attachment found" unless @attachment

      extension = @attachment.file_extension

      if @attachment.filename
        expected = File.extname(@attachment.filename).downcase.delete(".")
        assert_equal expected, extension
      else
        assert_nil extension
      end
    end

    def test_display_name
      skip_unless_full_disk_access
      skip "No attachment found" unless @attachment

      name = @attachment.display_name

      if @attachment.filename
        refute_nil name
      end
    end

    def test_file_size_mb
      skip_unless_full_disk_access
      skip "No attachment found" unless @attachment

      size = @attachment.file_size_mb

      if @attachment.total_bytes
        expected = (@attachment.total_bytes / 1024.0 / 1024.0).round(2)
        assert_equal expected, size
      else
        assert_nil size
      end
    end

    def test_file_type_description
      skip_unless_full_disk_access
      skip "No attachment found" unless @attachment

      description = @attachment.file_type_description
      refute_nil description
      assert_includes ["Image", "Video", "Audio", "Document", "File"], description
    end

    private

    def skip_unless_full_disk_access
      skip "Full Disk Access not available" unless Imessage::Db.full_disk_access?
    end
  end
end
