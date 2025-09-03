# frozen_string_literal: true

require "test_helper"

class MessageAttachmentTest < Minitest::Test
  def test_table_name
    assert_equal "message_attachment_join", Imessage::Db::MessageAttachment.table_name
  end

  def test_primary_key
    assert_equal "message_id", Imessage::Db::MessageAttachment.primary_key
  end

  def test_responds_to_association_methods
    assert Imessage::Db::MessageAttachment.method_defined?(:message)
    assert Imessage::Db::MessageAttachment.method_defined?(:attachment)
  end
end

# Integration tests that require Full Disk Access
class MessageAttachmentIntegrationTest < Minitest::Test
  def setup
    unless Imessage::Db.full_disk_access?
      skip "Full Disk Access not available. Please enable it in System Settings > Privacy & Security > Full Disk Access"
    end
    
    Imessage::Db::Database.establish_connection!
  end

  def teardown
    ActiveRecord::Base.remove_connection if ActiveRecord::Base.connected?
  end

  def test_can_connect_to_database
    count = Imessage::Db::MessageAttachment.count
    assert_kind_of Integer, count
  end

  def test_can_load_message_attachments
    message_attachments = Imessage::Db::MessageAttachment.limit(5)
    assert_kind_of ActiveRecord::Relation, message_attachments
    
    if message_attachments.any?
      message_attachment = message_attachments.first
      assert_kind_of Imessage::Db::MessageAttachment, message_attachment
      assert message_attachment.message_id
      assert message_attachment.attachment_id
    end
  end

  def test_belongs_to_message_association
    message_attachment = Imessage::Db::MessageAttachment.first
    
    if message_attachment
      # Test that the association method exists and can be called
      assert_respond_to message_attachment, :message
      
      # Test that we can load the associated message
      message = message_attachment.message
      if message
        assert_kind_of Imessage::Db::Message, message
        assert_equal message_attachment.message_id, message.ROWID
      end
    end
  end

  def test_belongs_to_attachment_association
    message_attachment = Imessage::Db::MessageAttachment.first
    
    if message_attachment
      # Test that the association method exists and can be called
      assert_respond_to message_attachment, :attachment
      
      # Note: We can't test the actual association without Attachment model being loaded
      # This test just ensures the association is defined correctly
    end
  end

  def test_foreign_key_constraints
    message_attachment = Imessage::Db::MessageAttachment.first
    
    if message_attachment
      assert message_attachment.message_id.is_a?(Integer)
      assert message_attachment.attachment_id.is_a?(Integer)
      assert message_attachment.message_id > 0
      assert message_attachment.attachment_id > 0
    end
  end

  def test_messages_with_attachments
    # Find messages that have attachments
    messages_with_attachments = Imessage::Db::Message
      .joins("JOIN message_attachment_join ON message.ROWID = message_attachment_join.message_id")
      .limit(3)
    
    messages_with_attachments.each do |message|
      assert_kind_of Imessage::Db::Message, message
      # Verify the message has the cache_has_attachments flag set (if available)
      if message.respond_to?(:cache_has_attachments)
        # This field indicates the message has attachments
        assert_equal 1, message.cache_has_attachments
      end
    end
  end

  def test_attachment_count_per_message
    # Test that we can count attachments per message
    message_attachment_counts = Imessage::Db::MessageAttachment
      .group(:message_id)
      .count
      .first(5)
    
    message_attachment_counts.each do |message_id, count|
      assert message_id.is_a?(Integer)
      assert count.is_a?(Integer)
      assert count > 0
    end
  end
end