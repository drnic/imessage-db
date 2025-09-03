# frozen_string_literal: true

module Imessage
  module Db
    # Apple's TypedStream format decoder for iMessage attributed strings and other objects
    # Based on reverse engineering work from:
    # - https://chrissardegna.com/blog/reverse-engineering-apples-typedstream-format
    # - https://github.com/mattt/Madrid/blob/main/Sources/TypedStream/TypedStreamDecoder.swift
    # - https://github.com/dgelessus/python-typedstream
    module TypedStream
      VERSION = 0x04

      # Stream byte indicators
      STREAM_START = 0x84
      STREAM_END = 0x86
      INHERITANCE_END = 0x85
      SHORT_INT_FLAG = 0x81

      # First cache index for types/objects
      CACHE_START_INDEX = 0x92

      # TypedStream parsing errors
      class ParseError < StandardError; end

      class InvalidHeaderError < ParseError; end

      class UnsupportedVersionError < ParseError; end

      class OutOfBoundsError < ParseError; end

      # Main decoder class
      class Decoder
        attr_reader :data, :position, :type_cache, :object_cache

        def initialize(data)
          @data = data.is_a?(String) ? data.unpack("C*") : data
          @position = 0
          @type_cache = []
          @object_cache = []
        end

        # Decode the entire typedstream
        def decode
          validate_header
          parse_stream
        end

        private

        def validate_header
          raise InvalidHeaderError, "Stream too short" if @data.length < 16

          version = read_byte
          raise UnsupportedVersionError, "Unsupported version: #{version}" if version != VERSION

          # Skip system info bytes (positions 1-15)
          @position = 16
        end

        def parse_stream
          results = []

          while @position < @data.length
            byte = peek_byte
            break if byte.nil?

            case byte
            when STREAM_START
              results << parse_object
            when STREAM_END
              break
            else
              @position += 1
            end
          end

          results
        end

        def parse_object
          consume_byte(STREAM_START)

          object = {}
          object[:class_hierarchy] = parse_class_hierarchy
          object[:data] = parse_object_data

          # Only consume STREAM_END if it's actually there
          if peek_byte == STREAM_END
            consume_byte(STREAM_END)
          end

          object
        end

        def parse_class_hierarchy
          hierarchy = []

          loop do
            byte = peek_byte
            break if byte == INHERITANCE_END

            class_name = parse_string
            hierarchy << class_name if class_name
          end

          consume_byte(INHERITANCE_END) if peek_byte == INHERITANCE_END
          hierarchy
        end

        def parse_object_data
          data = {}

          while @position < @data.length && peek_byte != STREAM_END
            # Try to parse key-value pairs, but handle single values too
            value = parse_value
            break if value.nil?

            # If we get a value, try to get another for key-value pair
            next_value = parse_value
            if next_value.nil?
              # Single value, use index as key
              data[@position] = value
            else
              # Key-value pair
              data[value] = next_value
            end
          end

          data
        end

        def parse_value
          byte = read_byte
          return nil if byte.nil?

          case byte
          when 0x00..0x7F
            # Direct value
            byte
          when SHORT_INT_FLAG
            # 16-bit integer follows
            parse_short_int
          when CACHE_START_INDEX..0xFF
            # Cache reference
            cache_index = byte - CACHE_START_INDEX
            @type_cache[cache_index] || @object_cache[cache_index]
          else
            # String or other data type
            parse_string_or_data(byte)
          end
        end

        def parse_short_int
          return nil if @position + 1 >= @data.length

          low = read_byte
          high = read_byte
          (high << 8) | low
        end

        def parse_string
          length = read_byte
          return nil if length.nil? || @position + length > @data.length

          string_bytes = @data[@position, length]
          @position += length
          string_bytes.pack("C*").force_encoding("UTF-8")
        rescue
          nil
        end

        def parse_string_or_data(first_byte)
          # Try to parse as string length
          if first_byte > 0 && @position + first_byte <= @data.length
            string_bytes = @data[@position, first_byte]
            @position += first_byte
            begin
              string_bytes.pack("C*").force_encoding("UTF-8")
            rescue
              string_bytes
            end
          else
            first_byte
          end
        end

        def read_byte
          return nil if @position >= @data.length

          byte = @data[@position]
          @position += 1
          byte
        end

        def peek_byte
          return nil if @position >= @data.length
          @data[@position]
        end

        def consume_byte(expected)
          byte = read_byte
          raise ParseError, "Expected #{expected}, got #{byte.inspect}" if byte != expected
        end
      end

      # High-level DSL for working with typedstream data
      class Parser
        def self.decode(data)
          return [] if data.nil? || data.empty?

          decoder = Decoder.new(data)
          decoder.decode
        rescue ParseError
          []
        end

        def self.parse_attributed_string(data)
          return nil if data.nil? || data.empty?

          objects = decode(data)
          return nil if objects.empty?

          result = AttributedString.from_objects(objects)
          # Return nil if we got an empty AttributedString from invalid data
          return nil if result && result.string.empty? && result.attributes.empty?

          result
        rescue
          nil
        end
      end

      # Represents a decoded attributed string
      class AttributedString
        attr_reader :string, :attributes

        def initialize(string = "", attributes = {})
          @string = string
          @attributes = attributes
        end

        def self.from_objects(objects)
          return new unless objects.is_a?(Array) && !objects.empty?

          # Look for NSAttributedString-like objects
          attr_string_obj = objects.find { |obj|
            obj.is_a?(Hash) &&
              obj[:class_hierarchy]&.any? { |cls| cls =~ /NSAttributedString|NSMutableAttributedString/i }
          }

          return new unless attr_string_obj

          # Extract string content and attributes
          string_content = extract_string_content(attr_string_obj)
          attributes = extract_attributes(attr_string_obj)

          new(string_content, attributes)
        end

        def to_s
          @string
        end

        def to_h
          {string: @string, attributes: @attributes}
        end

        def plain_text
          @string
        end

        def has_attributes?
          !@attributes.empty?
        end

        private

        def self.extract_string_content(obj)
          data = obj[:data] || {}

          # Look for string content in common keys
          content = data["NSString"] || data["string"] || data.values.find { |v| v.is_a?(String) && v.length > 0 }
          content || ""
        end

        def self.extract_attributes(obj)
          data = obj[:data] || {}

          # Look for attributes dictionary
          attrs = data["NSAttributes"] || data["attributes"] || {}
          attrs.is_a?(Hash) ? attrs : {}
        end
      end
    end
  end
end
