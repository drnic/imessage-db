# frozen_string_literal: true

require "spec_helper"

RSpec.describe Imessage::Db do
  describe ".apple_time_to_ruby" do
    it "converts Apple nanosecond timestamps to Ruby Time" do
      # Apple epoch starts at 2001-01-01 00:00:00 UTC
      # 1 second = 1_000_000_000 nanoseconds
      one_second_after_apple_epoch = 1_000_000_000
      result = described_class.apple_time_to_ruby(one_second_after_apple_epoch)
      
      expected_time = Time.new(2001, 1, 1, 0, 0, 1, "+00:00")
      expect(result).to eq(expected_time)
    end

    it "returns nil for nil input" do
      expect(described_class.apple_time_to_ruby(nil)).to be_nil
    end

    it "returns nil for zero input" do
      expect(described_class.apple_time_to_ruby(0)).to be_nil
    end

    it "handles fractional seconds correctly" do
      # 1.5 seconds = 1_500_000_000 nanoseconds
      one_and_half_seconds = 1_500_000_000
      result = described_class.apple_time_to_ruby(one_and_half_seconds)
      
      expected_time = Time.new(2001, 1, 1, 0, 0, 1.5, "+00:00")
      expect(result).to eq(expected_time)
    end
  end

  describe ".full_disk_access?" do
    it "checks if Full Disk Access is available" do
      result = described_class.full_disk_access?
      expect(result).to be_in([true, false])
    end
  end

  describe ".chat_db_path" do
    it "returns the correct path to Messages database" do
      expected_path = File.expand_path("~/Library/Messages/chat.db")
      expect(described_class.chat_db_path).to eq(expected_path)
    end
  end

  describe "constants" do
    it "defines APPLE_EPOCH correctly" do
      expect(described_class::APPLE_EPOCH).to eq(Time.new(2001, 1, 1, 0, 0, 0, "+00:00"))
    end
  end
end