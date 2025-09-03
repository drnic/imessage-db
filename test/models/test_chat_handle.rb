# frozen_string_literal: true

require "test_helper"

class ChatHandleTest < Minitest::Test
  def test_table_name
    assert_equal "chat_handle_join", Imessage::Db::ChatHandle.table_name
  end

  def test_primary_key
    assert_equal "chat_id", Imessage::Db::ChatHandle.primary_key
  end

  def test_responds_to_association_methods
    assert Imessage::Db::ChatHandle.method_defined?(:chat)
    assert Imessage::Db::ChatHandle.method_defined?(:handle)
  end
end

# Integration tests that require Full Disk Access
class ChatHandleIntegrationTest < Minitest::Test
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
    count = Imessage::Db::ChatHandle.count
    assert_kind_of Integer, count
  end

  def test_can_load_chat_handles
    chat_handles = Imessage::Db::ChatHandle.limit(5)
    assert_kind_of ActiveRecord::Relation, chat_handles

    if chat_handles.any?
      chat_handle = chat_handles.first
      assert_kind_of Imessage::Db::ChatHandle, chat_handle
      assert chat_handle.chat_id
      assert chat_handle.handle_id
    end
  end

  def test_belongs_to_chat_association
    chat_handle = Imessage::Db::ChatHandle.first

    if chat_handle
      # Test that the association method exists and can be called
      assert_respond_to chat_handle, :chat

      # Note: We can't test the actual association without Chat model being loaded
      # This test just ensures the association is defined correctly
    end
  end

  def test_belongs_to_handle_association
    chat_handle = Imessage::Db::ChatHandle.first

    if chat_handle
      # Test that the association method exists and can be called
      assert_respond_to chat_handle, :handle

      # Note: We can't test the actual association without Handle model being loaded
      # This test just ensures the association is defined correctly
    end
  end

  def test_foreign_key_constraints
    chat_handle = Imessage::Db::ChatHandle.first

    if chat_handle
      assert chat_handle.chat_id.is_a?(Integer)
      assert chat_handle.handle_id.is_a?(Integer)
      assert chat_handle.chat_id > 0
      assert chat_handle.handle_id > 0
    end
  end

  def test_unique_chat_handle_combinations
    # Test that we can find unique combinations of chat_id and handle_id
    chat_handles = Imessage::Db::ChatHandle.limit(10)

    if chat_handles.count > 1
      combinations = chat_handles.map { |ch| [ch.chat_id, ch.handle_id] }
      # Note: The actual uniqueness constraint is in the database schema
      # This test just verifies we can read the combinations
      assert_kind_of Array, combinations
      combinations.each do |combo|
        assert_equal 2, combo.length
        assert combo[0].is_a?(Integer)
        assert combo[1].is_a?(Integer)
      end
    end
  end
end
