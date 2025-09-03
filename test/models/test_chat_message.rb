# frozen_string_literal: true

require "test_helper"

class ChatMessageTest < Minitest::Test
  def test_table_name
    assert_equal "chat_message_join", Imessage::Db::ChatMessage.table_name
  end

  def test_primary_key
    assert_equal "chat_id", Imessage::Db::ChatMessage.primary_key
  end

  def test_responds_to_association_methods
    assert Imessage::Db::ChatMessage.method_defined?(:chat)
    assert Imessage::Db::ChatMessage.method_defined?(:message)
  end
end

# Integration tests that require Full Disk Access
class ChatMessageIntegrationTest < Minitest::Test
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
    count = Imessage::Db::ChatMessage.count
    assert_kind_of Integer, count
  end

  def test_can_load_chat_messages
    chat_messages = Imessage::Db::ChatMessage.limit(5)
    assert_kind_of ActiveRecord::Relation, chat_messages

    if chat_messages.any?
      chat_message = chat_messages.first
      assert_kind_of Imessage::Db::ChatMessage, chat_message
      assert chat_message.chat_id
      assert chat_message.message_id
    end
  end

  def test_belongs_to_chat_association
    chat_message = Imessage::Db::ChatMessage.first

    if chat_message
      # Test that the association method exists and can be called
      assert_respond_to chat_message, :chat

      # Note: We can't test the actual association without Chat model being loaded
      # This test just ensures the association is defined correctly
    end
  end

  def test_belongs_to_message_association
    chat_message = Imessage::Db::ChatMessage.first

    if chat_message
      # Test that the association method exists and can be called
      assert_respond_to chat_message, :message

      # Test that we can load the associated message
      message = chat_message.message
      if message
        assert_kind_of Imessage::Db::Message, message
        assert_equal chat_message.message_id, message.ROWID
      end
    end
  end

  def test_foreign_key_constraints
    chat_message = Imessage::Db::ChatMessage.first

    if chat_message
      assert chat_message.chat_id.is_a?(Integer)
      assert chat_message.message_id.is_a?(Integer)
      assert chat_message.chat_id > 0
      assert chat_message.message_id > 0
    end
  end
end
