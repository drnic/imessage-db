# frozen_string_literal: true

require "test_helper"

class TestHtmlMarkdownConversion < Minitest::Test
  def test_attributed_string_html_conversion_plain_text
    attr_string = Imessage::Db::TypedStream::AttributedString.new("Hello World")

    assert_equal "Hello World", attr_string.to_html
    assert_equal "Hello World", attr_string.to_markdown
  end

  def test_attributed_string_html_escaping
    attr_string = Imessage::Db::TypedStream::AttributedString.new("<script>alert('xss')</script>")

    expected_html = "&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;"
    assert_equal expected_html, attr_string.to_html
  end

  def test_attributed_string_bold_formatting
    attr_string = Imessage::Db::TypedStream::AttributedString.new(
      "Bold text",
      {"NSFont" => "Helvetica-Bold"}
    )

    assert_equal "<strong>Bold text</strong>", attr_string.to_html
    assert_equal "**Bold text**", attr_string.to_markdown
    assert attr_string.bold?
  end

  def test_attributed_string_italic_formatting
    attr_string = Imessage::Db::TypedStream::AttributedString.new(
      "Italic text",
      {"NSFont" => "Helvetica-Italic"}
    )

    assert_equal "<em>Italic text</em>", attr_string.to_html
    assert_equal "*Italic text*", attr_string.to_markdown
    assert attr_string.italic?
  end

  def test_attributed_string_link_formatting
    attr_string = Imessage::Db::TypedStream::AttributedString.new(
      "Click here",
      {"NSLink" => "https://example.com"}
    )

    assert_equal '<a href="https://example.com">Click here</a>', attr_string.to_html
    assert_equal "[Click here](https://example.com)", attr_string.to_markdown
    assert attr_string.link?
    assert_equal "https://example.com", attr_string.link_url
  end

  def test_attributed_string_underline_formatting
    attr_string = Imessage::Db::TypedStream::AttributedString.new(
      "Underlined text",
      {"NSUnderlineStyle" => "1"}
    )

    assert_equal "<u>Underlined text</u>", attr_string.to_html
    assert_equal "Underlined text", attr_string.to_markdown # Markdown doesn't support underline
    assert attr_string.underlined?
  end

  def test_attributed_string_color_formatting
    attr_string = Imessage::Db::TypedStream::AttributedString.new(
      "Red text",
      {"NSColor" => "red"}
    )

    assert_equal '<span style="color: #FF0000">Red text</span>', attr_string.to_html
    assert_equal "Red text", attr_string.to_markdown # Markdown doesn't support colors
    assert_equal "red", attr_string.color
  end

  def test_attributed_string_combined_formatting
    attr_string = Imessage::Db::TypedStream::AttributedString.new(
      "Bold red link",
      {
        "NSFont" => "Helvetica-Bold",
        "NSColor" => "red",
        "NSLink" => "https://example.com"
      }
    )

    expected_html = '<a href="https://example.com"><strong><span style="color: #FF0000">Bold red link</span></strong></a>'
    expected_markdown = "[**Bold red link**](https://example.com)"

    assert_equal expected_html, attr_string.to_html
    assert_equal expected_markdown, attr_string.to_markdown

    assert attr_string.bold?
    assert attr_string.link?
    assert_equal "red", attr_string.color
    assert_equal "https://example.com", attr_string.link_url
  end

  def test_attributed_string_html_with_link_options
    attr_string = Imessage::Db::TypedStream::AttributedString.new(
      "External link",
      {"NSLink" => "https://example.com"}
    )

    options = {link_attributes: {target: "_blank", rel: "noopener"}}
    expected = '<a href="https://example.com" target="_blank" rel="noopener">External link</a>'

    assert_equal expected, attr_string.to_html(options)
  end

  def test_attributed_string_color_css_conversion
    test_cases = [
      ["red", "#FF0000"],
      ["blue", "#0000FF"],
      ["green", "#00FF00"],
      ["#FF5733", "#FF5733"],
      ["#f57", "#f57"],
      ["unknown", "unknown"]
    ]

    test_cases.each do |input_color, expected_css|
      attr_string = Imessage::Db::TypedStream::AttributedString.new(
        "Colored text",
        {"NSColor" => input_color}
      )

      expected_html = %(<span style="color: #{expected_css}">Colored text</span>)
      assert_equal expected_html, attr_string.to_html
    end
  end

  def test_attributed_string_font_detection
    attr_string = Imessage::Db::TypedStream::AttributedString.new(
      "Font test",
      {"NSFont" => "Helvetica-BoldItalic"}
    )

    assert attr_string.bold?
    assert attr_string.italic?
    assert_equal "Helvetica-BoldItalic", attr_string.font
  end

  def test_message_html_conversion_with_attributed_text
    message = Imessage::Db::Message.new(text: "Fallback text", attributedBody: "mock_data")

    # Mock attributed string with formatting
    mock_attributed = Minitest::Mock.new
    mock_attributed.expect(:to_html, "<strong>Rich text</strong>", [Hash])

    message.stub(:attributed_string, mock_attributed) do
      assert_equal "<strong>Rich text</strong>", message.to_html
    end

    mock_attributed.verify
  end

  def test_message_markdown_conversion_with_attributed_text
    message = Imessage::Db::Message.new(text: "Fallback text", attributedBody: "mock_data")

    # Mock attributed string with formatting
    mock_attributed = Minitest::Mock.new
    mock_attributed.expect(:to_markdown, "**Rich text**")

    message.stub(:attributed_string, mock_attributed) do
      assert_equal "**Rich text**", message.to_markdown
    end

    mock_attributed.verify
  end

  def test_message_html_conversion_fallback_to_plain_text
    message = Imessage::Db::Message.new(text: "Plain <script> text", attributedBody: nil)

    expected = "Plain &lt;script&gt; text"
    assert_equal expected, message.to_html
  end

  def test_message_markdown_conversion_fallback_to_plain_text
    message = Imessage::Db::Message.new(text: "Plain text message", attributedBody: nil)

    assert_equal "Plain text message", message.to_markdown
  end

  def test_message_to_text_method
    message = Imessage::Db::Message.new(text: "Test message")

    assert_equal "Test message", message.to_text
  end

  def test_message_content_as_method
    message = Imessage::Db::Message.new(text: "Test <message>", attributedBody: nil)

    assert_equal "Test &lt;message&gt;", message.content_as(:html)
    assert_equal "Test &lt;message&gt;", message.content_as("html")
    assert_equal "Test <message>", message.content_as(:markdown)
    assert_equal "Test <message>", message.content_as("md")
    assert_equal "Test <message>", message.content_as(:text)
    assert_equal "Test <message>", message.content_as("plain")
  end

  def test_message_content_as_method_with_options
    message = Imessage::Db::Message.new(text: "Test message", attributedBody: "mock_data")

    # Mock attributed string with link
    mock_attributed = Minitest::Mock.new
    mock_attributed.expect(:to_html, '<a href="https://example.com" target="_blank">Test message</a>', [{link_attributes: {target: "_blank"}}])

    message.stub(:attributed_string, mock_attributed) do
      options = {link_attributes: {target: "_blank"}}
      result = message.content_as(:html, options)
      assert_equal '<a href="https://example.com" target="_blank">Test message</a>', result
    end

    mock_attributed.verify
  end

  def test_message_content_as_method_invalid_format
    message = Imessage::Db::Message.new(text: "Test message")

    error = assert_raises(ArgumentError) do
      message.content_as(:invalid)
    end

    assert_match(/Unknown format: invalid/, error.message)
    assert_match(/Supported formats: html, markdown, text/, error.message)
  end

  def test_message_html_escaping_edge_cases
    test_cases = [
      [nil, ""],
      ["", ""],
      ["Normal text", "Normal text"],
      ["<>&\"'", "&lt;&gt;&amp;&quot;&#39;"]
    ]

    test_cases.each do |input, expected|
      message = Imessage::Db::Message.new(text: input)
      assert_equal expected, message.to_html
    end
  end

  def test_attributed_string_attribute_access_methods
    attr_string = Imessage::Db::TypedStream::AttributedString.new(
      "Test text",
      {
        "NSFont" => "Helvetica-Bold",
        "NSColor" => "blue",
        "NSLink" => "https://test.com",
        "NSUnderlineStyle" => "1"
      }
    )

    # Test all boolean methods
    assert attr_string.bold?
    refute attr_string.italic?  # Not italic, just bold
    assert attr_string.link?
    assert attr_string.underlined?

    # Test value methods
    assert_equal "blue", attr_string.color
    assert_equal "Helvetica-Bold", attr_string.font
    assert_equal "https://test.com", attr_string.link_url
  end

  def test_attributed_string_no_attributes
    attr_string = Imessage::Db::TypedStream::AttributedString.new("Plain text", {})

    # All boolean methods should return false
    refute attr_string.bold?
    refute attr_string.italic?
    refute attr_string.link?
    refute attr_string.underlined?

    # All value methods should return nil
    assert_nil attr_string.color
    assert_nil attr_string.font
    assert_nil attr_string.link_url
  end
end
