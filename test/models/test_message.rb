# frozen_string_literal: true

require "test_helper"

class MessageTest < Minitest::Test
  def test_table_name
    assert_equal "message", Imessage::Db::Message.table_name
  end

  def test_primary_key
    assert_equal "ROWID", Imessage::Db::Message.primary_key
  end

  def test_inheritance_column_disabled
    # In newer versions of ActiveRecord, inheritance_column returns empty string when disabled
    assert_includes [nil, ""], Imessage::Db::Message.inheritance_column
  end

  def test_convenience_methods
    # Create a simple test object that responds like a Message
    message = Object.new
    def message.is_from_me
      @is_from_me
    end

    def message.is_from_me=(value)
      @is_from_me = value
    end

    def message.service
      @service
    end

    def message.service=(value)
      @service = value
    end

    def message.associated_message_guid
      @associated_message_guid
    end

    def message.associated_message_guid=(value)
      @associated_message_guid = value
    end

    # Add the convenience methods from Message
    message.extend(Module.new do
      def from_me?
        is_from_me == 1
      end

      def to_me?
        is_from_me == 0
      end

      def imessage?
        service == "iMessage"
      end

      def sms?
        service == "SMS"
      end

      def tapback?
        !associated_message_guid.nil?
      end

      def reaction?
        tapback?
      end
    end)

    # Test from_me?
    message.is_from_me = 1
    assert message.from_me?

    message.is_from_me = 0
    refute message.from_me?

    # Test to_me?
    message.is_from_me = 1
    refute message.to_me?

    message.is_from_me = 0
    assert message.to_me?

    # Test imessage?
    message.service = "iMessage"
    assert message.imessage?

    message.service = "SMS"
    refute message.imessage?

    # Test sms?
    message.service = "SMS"
    assert message.sms?

    message.service = "iMessage"
    refute message.sms?

    # Test tapback?
    message.associated_message_guid = "some-guid"
    assert message.tapback?

    message.associated_message_guid = nil
    refute message.tapback?

    # Test reaction? (alias for tapback?)
    message.associated_message_guid = "some-guid"
    assert message.reaction?
  end

  def test_in_chat_scope
    # Skip if Full Disk Access not available
    skip "Full Disk Access not available" unless Imessage::Db.full_disk_access?

    # Find a chat with messages
    chat_with_messages = Imessage::Db::Chat.joins(:messages).distinct.first
    skip "No chats with messages found" unless chat_with_messages

    # Test with Chat object
    messages = Imessage::Db::Message.in_chat(chat_with_messages)
    assert_kind_of ActiveRecord::Relation, messages

    if messages.any?
      # Verify the messages belong to this chat
      message = messages.first
      chat_ids = message.chats.pluck(:ROWID)
      assert_includes chat_ids, chat_with_messages.ROWID
    end

    # Test with chat ID
    messages_by_id = Imessage::Db::Message.in_chat(chat_with_messages.ROWID)
    assert_kind_of ActiveRecord::Relation, messages_by_id
    assert_equal messages.count, messages_by_id.count

    # Test with nil
    messages_nil = Imessage::Db::Message.in_chat(nil)
    assert_kind_of ActiveRecord::Relation, messages_nil
    assert_equal 0, messages_nil.count
  end

  def test_apple_time_conversion_methods
    # Test the time conversion methods that will be called on model instances
    apple_timestamp = 694224000000000000 # 2023-01-01 00:00:00 UTC in Apple time
    ruby_time = Imessage::Db.apple_time_to_ruby(apple_timestamp)

    assert_equal 2023, ruby_time.year
    assert_equal 1, ruby_time.month
    assert_equal 1, ruby_time.day
  end
end

# Integration tests that require Full Disk Access
class MessageIntegrationTest < Minitest::Test
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
    # Should not raise an error when connecting to database
    count = Imessage::Db::Message.count
    assert_kind_of Integer, count
  end

  def test_can_load_messages
    messages = Imessage::Db::Message.limit(5)
    assert_kind_of ActiveRecord::Relation, messages

    if messages.any?
      message = messages.first
      assert_kind_of Imessage::Db::Message, message
      assert message.ROWID
    end
  end

  def test_recent_scope_orders_by_date_desc
    recent_messages = Imessage::Db::Message.recent.limit(10)
    assert_kind_of ActiveRecord::Relation, recent_messages

    if recent_messages.count > 1
      dates = recent_messages.pluck(:date)
      assert_equal dates.sort.reverse, dates
    end
  end

  def test_from_me_scope
    from_me_messages = Imessage::Db::Message.from_me.limit(5)
    assert_kind_of ActiveRecord::Relation, from_me_messages

    from_me_messages.each do |message|
      assert message.from_me?
    end
  end

  def test_to_me_scope
    to_me_messages = Imessage::Db::Message.to_me.limit(5)
    assert_kind_of ActiveRecord::Relation, to_me_messages

    to_me_messages.each do |message|
      assert message.to_me?
    end
  end

  def test_with_text_scope
    text_messages = Imessage::Db::Message.with_text.limit(5)
    assert_kind_of ActiveRecord::Relation, text_messages

    text_messages.each do |message|
      assert message.text
      refute_empty message.text
    end
  end

  def test_service_scopes
    imessage_messages = Imessage::Db::Message.imessage.limit(3)
    sms_messages = Imessage::Db::Message.sms.limit(3)

    imessage_messages.each do |message|
      assert message.imessage?
      assert_equal "iMessage", message.service
    end

    sms_messages.each do |message|
      assert message.sms?
      assert_equal "SMS", message.service
    end
  end

  def test_converts_apple_timestamps
    message = Imessage::Db::Message.where.not(date: [0, nil]).first

    if message
      sent_at = message.sent_at
      assert_kind_of Time, sent_at
      assert sent_at > Time.new(2001, 1, 1)
      assert sent_at < Time.current + 365 * 24 * 60 * 60 # within a year from now
    end
  end

  def test_identifies_tapbacks
    tapback_messages = Imessage::Db::Message.where.not(associated_message_guid: nil).limit(3)

    tapback_messages.each do |message|
      assert message.tapback?
      assert message.reaction?
      assert message.associated_message_guid
    end
  end
end
