# frozen_string_literal: true

require "test_helper"

class TestAttributedString < Minitest::Test
  def test_attributed_string_initialization
    attr_string = Imessage::Db::TypedStream::AttributedString.new("Hello", {bold: true})

    assert_equal "Hello", attr_string.string
    assert_equal({bold: true}, attr_string.attributes)
  end

  def test_attributed_string_default_initialization
    attr_string = Imessage::Db::TypedStream::AttributedString.new

    assert_equal "", attr_string.string
    assert_equal({}, attr_string.attributes)
  end

  def test_to_s_method
    attr_string = Imessage::Db::TypedStream::AttributedString.new("Hello World")
    assert_equal "Hello World", attr_string.to_s
  end

  def test_plain_text_method
    attr_string = Imessage::Db::TypedStream::AttributedString.new("Hello World")
    assert_equal "Hello World", attr_string.plain_text
  end

  def test_to_h_method
    attr_string = Imessage::Db::TypedStream::AttributedString.new("Hello", {bold: true})
    expected = {string: "Hello", attributes: {bold: true}}
    assert_equal expected, attr_string.to_h
  end

  def test_has_attributes_true
    attr_string = Imessage::Db::TypedStream::AttributedString.new("Hello", {bold: true})
    assert attr_string.has_attributes?
  end

  def test_has_attributes_false
    attr_string = Imessage::Db::TypedStream::AttributedString.new("Hello")
    refute attr_string.has_attributes?
  end

  def test_from_objects_empty_array
    result = Imessage::Db::TypedStream::AttributedString.from_objects([])

    assert result.is_a?(Imessage::Db::TypedStream::AttributedString)
    assert_equal "", result.string
    assert_equal({}, result.attributes)
  end

  def test_from_objects_nil
    result = Imessage::Db::TypedStream::AttributedString.from_objects(nil)

    assert result.is_a?(Imessage::Db::TypedStream::AttributedString)
    assert_equal "", result.string
    assert_equal({}, result.attributes)
  end

  def test_from_objects_with_attributed_string
    objects = [
      {
        class_hierarchy: ["NSMutableAttributedString", "NSAttributedString"],
        data: {
          "NSString" => "Hello World",
          "NSAttributes" => {"NSFont" => "Helvetica"}
        }
      }
    ]

    result = Imessage::Db::TypedStream::AttributedString.from_objects(objects)

    assert result.is_a?(Imessage::Db::TypedStream::AttributedString)
    assert_equal "Hello World", result.string
    assert_equal({"NSFont" => "Helvetica"}, result.attributes)
    assert result.has_attributes?
  end

  def test_from_objects_without_attributed_string
    objects = [
      {
        class_hierarchy: ["NSString"],
        data: {"content" => "Just a string"}
      }
    ]

    result = Imessage::Db::TypedStream::AttributedString.from_objects(objects)

    assert result.is_a?(Imessage::Db::TypedStream::AttributedString)
    assert_equal "", result.string
    assert_equal({}, result.attributes)
  end

  def test_from_objects_with_various_string_keys
    objects = [
      {
        class_hierarchy: ["NSAttributedString"],
        data: {
          "string" => "Hello from string key",
          "other_data" => 123
        }
      }
    ]

    result = Imessage::Db::TypedStream::AttributedString.from_objects(objects)

    assert result.is_a?(Imessage::Db::TypedStream::AttributedString)
    assert_equal "Hello from string key", result.string
  end

  def test_from_objects_finds_any_string_value
    objects = [
      {
        class_hierarchy: ["NSAttributedString"],
        data: {
          "number" => 42,
          "random_key" => "Found me!",
          "empty" => ""
        }
      }
    ]

    result = Imessage::Db::TypedStream::AttributedString.from_objects(objects)

    assert result.is_a?(Imessage::Db::TypedStream::AttributedString)
    assert_equal "Found me!", result.string
  end
end
