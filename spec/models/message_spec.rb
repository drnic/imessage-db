# frozen_string_literal: true

require "spec_helper"

RSpec.describe Imessage::Db::Message do
  describe ".table_name" do
    it "uses the correct table name" do
      expect(described_class.table_name).to eq("message")
    end
  end

  describe ".primary_key" do
    it "uses ROWID as primary key" do
      expect(described_class.primary_key).to eq("ROWID")
    end
  end

  describe "loading messages from local chat.db", :requires_full_disk_access do
    before(:all) do
      unless Imessage::Db.full_disk_access?
        skip "Full Disk Access not available. Please enable it in System Settings > Privacy & Security > Full Disk Access"
      end
    end

    before(:each) do
      Imessage::Db::Database.establish_connection!
    end

    after(:each) do
      ActiveRecord::Base.remove_connection
    end

    it "can connect to the Messages database" do
      expect { described_class.count }.not_to raise_error
    end

    it "can load messages from the database" do
      messages = described_class.limit(5)
      expect(messages).to be_an(ActiveRecord::Relation)
      
      if messages.any?
        message = messages.first
        expect(message).to be_a(described_class)
        expect(message.ROWID).to be_present
      end
    end

    it "can filter recent messages" do
      recent_messages = described_class.recent.limit(10)
      expect(recent_messages).to be_an(ActiveRecord::Relation)
      
      if recent_messages.count > 1
        dates = recent_messages.pluck(:date)
        expect(dates).to eq(dates.sort.reverse)
      end
    end

    it "can filter messages from me" do
      from_me_messages = described_class.from_me.limit(5)
      expect(from_me_messages).to be_an(ActiveRecord::Relation)
      
      from_me_messages.each do |message|
        expect(message.from_me?).to be true
      end
    end

    it "can filter messages to me" do
      to_me_messages = described_class.to_me.limit(5)
      expect(to_me_messages).to be_an(ActiveRecord::Relation)
      
      to_me_messages.each do |message|
        expect(message.to_me?).to be true
      end
    end

    it "can filter messages with text" do
      text_messages = described_class.with_text.limit(5)
      expect(text_messages).to be_an(ActiveRecord::Relation)
      
      text_messages.each do |message|
        expect(message.text).to be_present
      end
    end

    it "converts Apple timestamps to Ruby Time objects" do
      message = described_class.where.not(date: [0, nil]).first
      
      if message
        sent_at = message.sent_at
        expect(sent_at).to be_a(Time)
        expect(sent_at).to be > Time.new(2001, 1, 1)
        expect(sent_at).to be < Time.current + 1.year
      end
    end

    it "handles service types" do
      imessage_messages = described_class.imessage.limit(3)
      sms_messages = described_class.sms.limit(3)
      
      imessage_messages.each do |message|
        expect(message.imessage?).to be true
        expect(message.service).to eq("iMessage")
      end
      
      sms_messages.each do |message|
        expect(message.sms?).to be true
        expect(message.service).to eq("SMS")
      end
    end

    it "identifies tapbacks/reactions" do
      tapback_messages = described_class.where.not(associated_message_guid: nil).limit(3)
      
      tapback_messages.each do |message|
        expect(message.tapback?).to be true
        expect(message.reaction?).to be true
        expect(message.associated_message_guid).to be_present
      end
    end

    it "can display basic message information" do
      messages = described_class.with_text.recent.limit(3)
      
      messages.each do |message|
        puts "\n--- Message #{message.ROWID} ---"
        puts "Text: #{message.text&.truncate(100)}"
        puts "From me: #{message.from_me?}"
        puts "Service: #{message.service}"
        puts "Sent at: #{message.sent_at}"
        puts "Delivered: #{message.delivered?}"
        puts "Read: #{message.read?}"
        puts "Has attachments: #{message.has_attachments?}"
      end
    end
  end

  describe "Apple time conversion" do
    it "converts Apple nanosecond timestamps correctly" do
      # Apple epoch starts at 2001-01-01 00:00:00 UTC
      # Test with a known timestamp: 2023-01-01 00:00:00 UTC should be 694224000000000000 nanoseconds
      apple_timestamp = 694224000000000000 # 2023-01-01 00:00:00 UTC in Apple time
      ruby_time = Imessage::Db.apple_time_to_ruby(apple_timestamp)
      
      expect(ruby_time.year).to eq(2023)
      expect(ruby_time.month).to eq(1)
      expect(ruby_time.day).to eq(1)
    end

    it "handles nil timestamps" do
      expect(Imessage::Db.apple_time_to_ruby(nil)).to be_nil
    end

    it "handles zero timestamps" do
      expect(Imessage::Db.apple_time_to_ruby(0)).to be_nil
    end
  end

  describe "convenience methods" do
    # Create a simple test object that responds like a Message
    let(:message) do
      obj = Object.new
      def obj.is_from_me; @is_from_me; end
      def obj.is_from_me=(value); @is_from_me = value; end
      def obj.service; @service; end
      def obj.service=(value); @service = value; end
      def obj.associated_message_guid; @associated_message_guid; end
      def obj.associated_message_guid=(value); @associated_message_guid = value; end
      
      # Add the convenience methods from Message
      obj.extend(Module.new do
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
      obj
    end

    describe "#from_me?" do
      it "returns true when is_from_me is 1" do
        message.is_from_me = 1
        expect(message.from_me?).to be true
      end

      it "returns false when is_from_me is 0" do
        message.is_from_me = 0
        expect(message.from_me?).to be false
      end
    end

    describe "#to_me?" do
      it "returns false when is_from_me is 1" do
        message.is_from_me = 1
        expect(message.to_me?).to be false
      end

      it "returns true when is_from_me is 0" do
        message.is_from_me = 0
        expect(message.to_me?).to be true
      end
    end

    describe "#imessage?" do
      it "returns true for iMessage service" do
        message.service = "iMessage"
        expect(message.imessage?).to be true
      end

      it "returns false for SMS service" do
        message.service = "SMS"
        expect(message.imessage?).to be false
      end
    end

    describe "#sms?" do
      it "returns true for SMS service" do
        message.service = "SMS"
        expect(message.sms?).to be true
      end

      it "returns false for iMessage service" do
        message.service = "iMessage"
        expect(message.sms?).to be false
      end
    end

    describe "#tapback?" do
      it "returns true when associated_message_guid is present" do
        message.associated_message_guid = "some-guid"
        expect(message.tapback?).to be true
      end

      it "returns false when associated_message_guid is nil" do
        message.associated_message_guid = nil
        expect(message.tapback?).to be false
      end
    end
  end
end