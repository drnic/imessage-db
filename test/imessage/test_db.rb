# frozen_string_literal: true

require "test_helper"

class Imessage::DbTest < Minitest::Test
  def test_apple_time_to_ruby_converts_nanosecond_timestamps
    # Apple epoch starts at 2001-01-01 00:00:00 UTC
    # 1 second = 1_000_000_000 nanoseconds
    one_second_after_apple_epoch = 1_000_000_000
    result = Imessage::Db.apple_time_to_ruby(one_second_after_apple_epoch)
    
    expected_time = Time.new(2001, 1, 1, 0, 0, 1, "+00:00")
    assert_equal expected_time, result
  end

  def test_apple_time_to_ruby_returns_nil_for_nil_input
    assert_nil Imessage::Db.apple_time_to_ruby(nil)
  end

  def test_apple_time_to_ruby_returns_nil_for_zero_input
    assert_nil Imessage::Db.apple_time_to_ruby(0)
  end

  def test_apple_time_to_ruby_handles_fractional_seconds
    # 1.5 seconds = 1_500_000_000 nanoseconds
    one_and_half_seconds = 1_500_000_000
    result = Imessage::Db.apple_time_to_ruby(one_and_half_seconds)
    
    expected_time = Time.new(2001, 1, 1, 0, 0, 1.5, "+00:00")
    assert_equal expected_time, result
  end

  def test_full_disk_access_returns_boolean
    result = Imessage::Db.full_disk_access?
    assert_includes [true, false], result
  end

  def test_chat_db_path_returns_test_path_when_set
    # In test environment, we've set it to use the test database
    expected_path = File.expand_path("../../db/test.db", __dir__)
    assert_equal expected_path, Imessage::Db.chat_db_path
  end
  
  def test_chat_db_path_assignment_works
    original_path = Imessage::Db.chat_db_path
    custom_path = "/tmp/custom_chat.db"
    
    Imessage::Db.chat_db_path = custom_path
    assert_equal custom_path, Imessage::Db.chat_db_path
    
    # Restore original path
    Imessage::Db.chat_db_path = original_path
  end

  def test_apple_epoch_constant_defined
    expected_time = Time.new(2001, 1, 1, 0, 0, 0, "+00:00")
    assert_equal expected_time, Imessage::Db::APPLE_EPOCH
  end

  def test_that_it_has_a_version_number
    refute_nil ::Imessage::Db::VERSION
  end
end
