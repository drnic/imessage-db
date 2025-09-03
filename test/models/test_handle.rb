# frozen_string_literal: true

require "test_helper"

module Imessage::Db
  class TestHandle < Minitest::Test
    def setup
      skip_unless_full_disk_access
      @handle = Handle.first
    end

    # Basic model tests
    def test_table_name
      assert_equal "handle", Handle.table_name
    end

    def test_primary_key
      assert_equal "ROWID", Handle.primary_key
    end

    # Association tests
    def test_has_many_messages
      skip_unless_full_disk_access
      skip "No handle found" unless @handle

      assert_respond_to @handle, :messages
      assert_kind_of ActiveRecord::Associations::CollectionProxy, @handle.messages
    end

    def test_has_many_chats
      skip_unless_full_disk_access
      skip "No handle found" unless @handle

      assert_respond_to @handle, :chats
      assert_kind_of ActiveRecord::Associations::CollectionProxy, @handle.chats
    end

    # Scope tests
    def test_by_service_scope
      skip_unless_full_disk_access

      handles = Handle.by_service("iMessage")
      assert_kind_of ActiveRecord::Relation, handles

      if handles.any?
        assert_equal "iMessage", handles.first.service
      end
    end

    def test_imessage_scope
      skip_unless_full_disk_access

      handles = Handle.imessage
      assert_kind_of ActiveRecord::Relation, handles

      if handles.any?
        assert_equal "iMessage", handles.first.service
      end
    end

    def test_sms_scope
      skip_unless_full_disk_access

      handles = Handle.sms
      assert_kind_of ActiveRecord::Relation, handles

      if handles.any?
        assert_equal "SMS", handles.first.service
      end
    end

    # Convenience method tests
    def test_phone_number_method
      skip_unless_full_disk_access
      skip "No handle found" unless @handle

      result = @handle.phone_number?
      assert [true, false].include?(result)

      if @handle.id.to_s.match?(/^\+?\d+$/)
        assert result
      else
        refute result
      end
    end

    def test_email_method
      skip_unless_full_disk_access
      skip "No handle found" unless @handle

      result = @handle.email?
      assert [true, false].include?(result)

      if @handle.id.to_s.include?("@")
        assert result
      else
        refute result
      end
    end

    def test_imessage_method
      skip_unless_full_disk_access
      skip "No handle found" unless @handle

      if @handle.service == "iMessage"
        assert @handle.imessage?
        refute @handle.sms?
      end
    end

    def test_sms_method
      skip_unless_full_disk_access
      skip "No handle found" unless @handle

      if @handle.service == "SMS"
        assert @handle.sms?
        refute @handle.imessage?
      end
    end

    def test_display_name
      skip_unless_full_disk_access
      skip "No handle found" unless @handle

      name = @handle.display_name
      refute_nil name
      assert_kind_of String, name
    end

    private

    def skip_unless_full_disk_access
      skip "Full Disk Access not available" unless Imessage::Db.full_disk_access?
    end
  end
end
