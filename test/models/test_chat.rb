# frozen_string_literal: true

require "test_helper"

module Imessage::Db
  class TestChat < Minitest::Test
    def setup
      skip_unless_full_disk_access
      @chat = Chat.first
    end

    # Basic model tests
    def test_table_name
      assert_equal "chat", Chat.table_name
    end

    def test_primary_key
      assert_equal "ROWID", Chat.primary_key
    end

    # Association tests
    def test_has_many_messages
      skip_unless_full_disk_access
      assert_respond_to @chat, :messages
      assert_kind_of ActiveRecord::Associations::CollectionProxy, @chat.messages
    end

    def test_has_many_handles
      skip_unless_full_disk_access
      assert_respond_to @chat, :handles
      assert_kind_of ActiveRecord::Associations::CollectionProxy, @chat.handles
    end

    # Scope tests
    def test_recent_scope
      skip_unless_full_disk_access
      recent_chats = Chat.recent.limit(5)
      assert_kind_of ActiveRecord::Relation, recent_chats

      # Verify ordering if we have multiple chats
      if recent_chats.to_a.size > 1
        first_chat = recent_chats.first
        second_chat = recent_chats.second

        # Recent scope orders by MAX(message.date) DESC
        first_max_date = first_chat.messages.maximum(:date)
        second_max_date = second_chat.messages.maximum(:date)

        assert first_max_date.to_i >= second_max_date.to_i if first_max_date && second_max_date
      end
    end

    def test_active_scope
      skip_unless_full_disk_access
      # active is an alias for recent
      active_chats = Chat.active.limit(5)
      recent_chats = Chat.recent.limit(5)

      assert_equal recent_chats.pluck(:ROWID), active_chats.pluck(:ROWID)
    end

    def test_with_participant_scope
      skip_unless_full_disk_access

      # Skip if no handles exist
      first_handle = Handle.first
      skip "No handles found in database" unless first_handle

      # Find chats with this participant
      chats_with_participant = Chat.with_participant(first_handle.id)
      assert_kind_of ActiveRecord::Relation, chats_with_participant

      # Verify the chat includes this handle
      if chats_with_participant.any?
        chat = chats_with_participant.first
        handle_ids = chat.handles.pluck(:id)
        assert handle_ids.any? { |id| id.to_s.include?(first_handle.id.to_s.gsub(/^\+?1/, "")) }
      end
    end

    def test_with_participant_scope_with_phone_number
      skip_unless_full_disk_access

      # Test with various phone number formats
      phone = "5551234567"
      chats = Chat.with_participant(phone)
      assert_kind_of ActiveRecord::Relation, chats

      # Test with +1 prefix
      chats_with_prefix = Chat.with_participant("+1#{phone}")
      assert_kind_of ActiveRecord::Relation, chats_with_prefix
    end

    def test_with_participant_scope_with_email
      skip_unless_full_disk_access

      email = "test@example.com"
      chats = Chat.with_participant(email)
      assert_kind_of ActiveRecord::Relation, chats
    end

    def test_with_participant_scope_with_nil
      chats = Chat.with_participant(nil)
      assert_kind_of ActiveRecord::Relation, chats
      assert_equal 0, chats.count
    end

    def test_with_participant_scope_with_empty_string
      chats = Chat.with_participant("")
      assert_kind_of ActiveRecord::Relation, chats
      assert_equal 0, chats.count
    end

    def test_imessage_scope
      skip_unless_full_disk_access
      imessage_chats = Chat.imessage
      assert_kind_of ActiveRecord::Relation, imessage_chats

      if imessage_chats.any?
        assert_equal "iMessage", imessage_chats.first.service_name
      end
    end

    def test_sms_scope
      skip_unless_full_disk_access
      sms_chats = Chat.sms
      assert_kind_of ActiveRecord::Relation, sms_chats

      if sms_chats.any?
        assert_equal "SMS", sms_chats.first.service_name
      end
    end

    def test_group_chats_scope
      skip_unless_full_disk_access
      group_chats = Chat.group_chats
      assert_kind_of ActiveRecord::Relation, group_chats

      if group_chats.any?
        refute_nil group_chats.first.display_name
        refute_empty group_chats.first.display_name
      end
    end

    def test_direct_messages_scope
      skip_unless_full_disk_access
      direct_messages = Chat.direct_messages
      assert_kind_of ActiveRecord::Relation, direct_messages

      if direct_messages.any?
        chat = direct_messages.first
        assert chat.display_name.nil? || chat.display_name.empty?
      end
    end

    # Convenience method tests
    def test_imessage_method
      skip_unless_full_disk_access
      skip "No chat found" unless @chat

      if @chat.service_name == "iMessage"
        assert @chat.imessage?
        assert !@chat.sms?
      end
    end

    def test_sms_method
      skip_unless_full_disk_access
      skip "No chat found" unless @chat

      if @chat.service_name == "SMS"
        assert @chat.sms?
        assert !@chat.imessage?
      end
    end

    def test_group_chat_method
      skip_unless_full_disk_access
      skip "No chat found" unless @chat

      if @chat.display_name.present?
        assert @chat.group_chat?
        assert !@chat.direct_message?
      end
    end

    def test_direct_message_method
      skip_unless_full_disk_access
      skip "No chat found" unless @chat

      if @chat.display_name.nil? || @chat.display_name.empty?
        assert @chat.direct_message?
        assert !@chat.group_chat?
      end
    end

    def test_title_method
      skip_unless_full_disk_access
      skip "No chat found" unless @chat

      title = @chat.title
      refute_nil title

      if @chat.group_chat?
        assert_equal @chat.display_name, title
      else
        expected = @chat.chat_identifier || "Unknown Chat"
        assert_equal expected, title
      end
    end

    def test_participant_identifiers
      skip_unless_full_disk_access
      skip "No chat found" unless @chat

      identifiers = @chat.participant_identifiers
      assert_kind_of Array, identifiers

      if @chat.chat_identifier
        assert identifiers.any?
      end
    end

    private

    def skip_unless_full_disk_access
      skip "Full Disk Access not available" unless Imessage::Db.full_disk_access?
    end
  end
end
