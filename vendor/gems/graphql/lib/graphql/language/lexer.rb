# frozen_string_literal: true
module GraphQL
  module Language

    class Lexer
      def initialize(graphql_str, filename: nil, max_tokens: nil)
        if !(graphql_str.encoding == Encoding::UTF_8 || graphql_str.ascii_only?)
          graphql_str = graphql_str.dup.force_encoding(Encoding::UTF_8)
        end
        @string = graphql_str
        @filename = filename
        @scanner = StringScanner.new(graphql_str)
        @pos = nil
        @max_tokens = max_tokens || Float::INFINITY
        @tokens_count = 0
      end

      def eos?
        @scanner.eos?
      end

      attr_reader :pos, :tokens_count

      def advance
        @scanner.skip(IGNORE_REGEXP)
        return false if @scanner.eos?
        @tokens_count += 1
        if @tokens_count > @max_tokens
          raise_parse_error("This query is too large to execute.")
        end
        @pos = @scanner.pos
        next_byte = @string.getbyte(@pos)
        next_byte_is_for = FIRST_BYTES[next_byte]
        case next_byte_is_for
        when ByteFor::PUNCTUATION
          @scanner.pos += 1
          PUNCTUATION_NAME_FOR_BYTE[next_byte]
        when ByteFor::NAME
          if len = @scanner.skip(KEYWORD_REGEXP)
            case len
            when 2
              :ON
            when 12
              :SUBSCRIPTION
            else
              pos = @pos

              # Use bytes 2 and 3 as a unique identifier for this keyword
              bytes = (@string.getbyte(pos + 2) << 8) | @string.getbyte(pos + 1)
              KEYWORD_BY_TWO_BYTES[_hash(bytes)]
            end
          else
            @scanner.skip(IDENTIFIER_REGEXP)
            :IDENTIFIER
          end
        when ByteFor::IDENTIFIER
          @scanner.skip(IDENTIFIER_REGEXP)
          :IDENTIFIER
        when ByteFor::NUMBER
          if len = @scanner.skip(NUMERIC_REGEXP)

            if GraphQL.reject_numbers_followed_by_names
              new_pos = @scanner.pos
              peek_byte = @string.getbyte(new_pos)
              next_first_byte = FIRST_BYTES[peek_byte]
              if next_first_byte == ByteFor::NAME || next_first_byte == ByteFor::IDENTIFIER
                number_part = token_value
                name_part = @scanner.scan(IDENTIFIER_REGEXP)
                raise_parse_error("Name after number is not allowed (in `#{number_part}#{name_part}`)")
              end
            end
            # Check for a matched decimal:
            @scanner[1] ? :FLOAT : :INT
          else
            # Attempt to find the part after the `-`
            value = @scanner.scan(/-\s?[a-z0-9]*/i)
            invalid_byte_for_number_error_message = "Expected type 'number', but it was malformed#{value.nil? ? "" : ": #{value.inspect}"}."
            raise_parse_error(invalid_byte_for_number_error_message)
          end
        when ByteFor::ELLIPSIS
          if @string.getbyte(@pos + 1) != 46 || @string.getbyte(@pos + 2) != 46
            raise_parse_error("Expected `...`, actual: #{@string[@pos..@pos + 2].inspect}")
          end
          @scanner.pos += 3
          :ELLIPSIS
        when ByteFor::STRING
          if @scanner.skip(BLOCK_STRING_REGEXP) || @scanner.skip(QUOTED_STRING_REGEXP)
            :STRING
          else
            raise_parse_error("Expected string or block string, but it was malformed")
          end
        else
          @scanner.pos += 1
          :UNKNOWN_CHAR
        end
      rescue ArgumentError => err
        if err.message == "invalid byte sequence in UTF-8"
          raise_parse_error("Parse error on bad Unicode escape sequence", nil, nil)
        end
      end

      def token_value
        @string.byteslice(@scanner.pos - @scanner.matched_size, @scanner.matched_size)
      rescue StandardError => err
        raise GraphQL::Error, "(token_value failed: #{err.class}: #{err.message})"
      end

      def debug_token_value(token_name)
        if token_name && Lexer::Punctuation.const_defined?(token_name)
          Lexer::Punctuation.const_get(token_name)
        elsif token_name == :ELLIPSIS
          "..."
        elsif token_name == :STRING
          string_value
        elsif @scanner.matched_size.nil?
          @scanner.peek(1)
        else
          token_value
        end
      end

      ESCAPES = /\\["\\\/bfnrt]/
      ESCAPES_REPLACE = {
        '\\"' => '"',
        "\\\\" => "\\",
        "\\/" => '/',
        "\\b" => "\b",
        "\\f" => "\f",
        "\\n" => "\n",
        "\\r" => "\r",
        "\\t" => "\t",
      }
      UTF_8 = /\\u(?:([\dAa-f]{4})|\{([\da-f]{4,})\})(?:\\u([\dAa-f]{4}))?/i
      VALID_STRING = /\A(?:[^\\]|#{ESCAPES}|#{UTF_8})*\z/o
      ESCAPED = /(?:#{ESCAPES}|#{UTF_8})/o

      def string_value
        str = token_value
        is_block = str.start_with?('"""')
        if is_block
          str.gsub!(/\A"""|"""\z/, '')
          return Language::BlockString.trim_whitespace(str)
        else
          str.gsub!(/\A"|"\z/, '')

          if !str.valid_encoding? || !str.match?(VALID_STRING)
            raise_parse_error("Bad unicode escape in #{str.inspect}")
          else
            Lexer.replace_escaped_characters_in_place(str)

            if !str.valid_encoding?
              raise_parse_error("Bad unicode escape in #{str.inspect}")
            else
              str
            end
          end
        end
      end

      def line_number
        @scanner.string[0..@pos].count("\n") + 1
      end

      def column_number
        @scanner.string[0..@pos].split("\n").last.length
      end

      def raise_parse_error(message, line = line_number, col = column_number)
        raise GraphQL::ParseError.new(message, line, col, @string, filename: @filename)
      end

      IGNORE_REGEXP = %r{
        (?:
          [, \c\r\n\t]+ |
          \#.*$
        )*
      }x
      IDENTIFIER_REGEXP = /[_A-Za-z][_0-9A-Za-z]*/
      INT_REGEXP =        /-?(?:[0]|[1-9][0-9]*)/
      FLOAT_DECIMAL_REGEXP = /[.][0-9]+/
      FLOAT_EXP_REGEXP =     /[eE][+-]?[0-9]+/
      # TODO: FLOAT_EXP_REGEXP should not be allowed to follow INT_REGEXP, integers are not allowed to have exponent parts.
      NUMERIC_REGEXP =  /#{INT_REGEXP}(#{FLOAT_DECIMAL_REGEXP}#{FLOAT_EXP_REGEXP}|#{FLOAT_DECIMAL_REGEXP}|#{FLOAT_EXP_REGEXP})?/

      KEYWORDS = [
        "on",
        "fragment",
        "true",
        "false",
        "null",
        "query",
        "mutation",
        "subscription",
        "schema",
        "scalar",
        "type",
        "extend",
        "implements",
        "interface",
        "union",
        "enum",
        "input",
        "directive",
        "repeatable"
      ].freeze

      KEYWORD_REGEXP = /#{Regexp.union(KEYWORDS.sort)}\b/
      KEYWORD_BY_TWO_BYTES = [
        :INTERFACE,
        :MUTATION,
        :EXTEND,
        :FALSE,
        :ENUM,
        :TRUE,
        :NULL,
        nil,
        nil,
        nil,
        nil,
        nil,
        nil,
        nil,
        :QUERY,
        nil,
        nil,
        :REPEATABLE,
        :IMPLEMENTS,
        :INPUT,
        :TYPE,
        :SCHEMA,
        nil,
        nil,
        nil,
        :DIRECTIVE,
        :UNION,
        nil,
        nil,
        :SCALAR,
        nil,
        :FRAGMENT
      ]

      # This produces a unique integer for bytes 2 and 3 of each keyword string
      # See https://tenderlovemaking.com/2023/09/02/fast-tokenizers-with-stringscanner.html
      def _hash key
        (key * 18592990) >> 27 & 0x1f
      end

      module Punctuation
        LCURLY =        '{'
        RCURLY =        '}'
        LPAREN =        '('
        RPAREN =        ')'
        LBRACKET =      '['
        RBRACKET =      ']'
        COLON =         ':'
        VAR_SIGN =      '$'
        DIR_SIGN =      '@'
        EQUALS =        '='
        BANG =          '!'
        PIPE =          '|'
        AMP =           '&'
      end

      # A sparse array mapping the bytes for each punctuation
      # to a symbol name for that punctuation
      PUNCTUATION_NAME_FOR_BYTE = Punctuation.constants.each_with_object([]) { |name, arr|
        punct = Punctuation.const_get(name)
        arr[punct.ord] = name
      }

      QUOTE =         '"'
      UNICODE_DIGIT = /[0-9A-Za-z]/
      FOUR_DIGIT_UNICODE = /#{UNICODE_DIGIT}{4}/
      N_DIGIT_UNICODE = %r{#{Punctuation::LCURLY}#{UNICODE_DIGIT}{4,}#{Punctuation::RCURLY}}x
      UNICODE_ESCAPE = %r{\\u(?:#{FOUR_DIGIT_UNICODE}|#{N_DIGIT_UNICODE})}
      STRING_ESCAPE = %r{[\\][\\/bfnrt]}
      BLOCK_QUOTE =   '"""'
      ESCAPED_QUOTE = /\\"/;
      STRING_CHAR = /#{ESCAPED_QUOTE}|[^"\\\n\r]|#{UNICODE_ESCAPE}|#{STRING_ESCAPE}/
      QUOTED_STRING_REGEXP = %r{#{QUOTE} (?:#{STRING_CHAR})* #{QUOTE}}x
      BLOCK_STRING_REGEXP = %r{
        #{BLOCK_QUOTE}
        (?: [^"\\]               |  # Any characters that aren't a quote or slash
           (?<!") ["]{1,2} (?!") |  # Any quotes that don't have quotes next to them
           \\"{0,3}(?!")         |  # A slash followed by <= 3 quotes that aren't followed by a quote
           \\                    |  # A slash
           "{1,2}(?!")              # 1 or 2 " followed by something that isn't a quote
        )*
        (?:"")?
        #{BLOCK_QUOTE}
      }xm

      # Use this array to check, for a given byte that will start a token,
      # what kind of token might it start?
      FIRST_BYTES = Array.new(255)

      module ByteFor
        NUMBER = 0 # int or float
        NAME = 1 # identifier or keyword
        STRING = 2
        ELLIPSIS = 3
        IDENTIFIER = 4 # identifier, *not* a keyword
        PUNCTUATION = 5
      end

      (0..9).each { |i| FIRST_BYTES[i.to_s.ord] = ByteFor::NUMBER }
      FIRST_BYTES["-".ord] = ByteFor::NUMBER
      # Some of these may be overwritten below, if keywords start with the same character
      ("A".."Z").each { |char| FIRST_BYTES[char.ord] = ByteFor::IDENTIFIER }
      ("a".."z").each { |char| FIRST_BYTES[char.ord] = ByteFor::IDENTIFIER }
      FIRST_BYTES['_'.ord] = ByteFor::IDENTIFIER
      FIRST_BYTES['.'.ord] = ByteFor::ELLIPSIS
      FIRST_BYTES['"'.ord] = ByteFor::STRING
      KEYWORDS.each { |kw| FIRST_BYTES[kw.getbyte(0)] = ByteFor::NAME }
      Punctuation.constants.each do |punct_name|
        punct = Punctuation.const_get(punct_name)
        FIRST_BYTES[punct.ord] = ByteFor::PUNCTUATION
      end


      # Replace any escaped unicode or whitespace with the _actual_ characters
      # To avoid allocating more strings, this modifies the string passed into it
      def self.replace_escaped_characters_in_place(raw_string)
        raw_string.gsub!(ESCAPED) do |matched_str|
          if (point_str_1 = $1 || $2)
            codepoint_1 = point_str_1.to_i(16)
            if (codepoint_2 = $3)
              codepoint_2 = codepoint_2.to_i(16)
              if (codepoint_1 >= 0xD800 && codepoint_1 <= 0xDBFF) && # leading surrogate
                  (codepoint_2 >= 0xDC00 && codepoint_2 <= 0xDFFF) # trailing surrogate
                # A surrogate pair
                combined = ((codepoint_1 - 0xD800) * 0x400) + (codepoint_2 - 0xDC00) + 0x10000
                [combined].pack('U'.freeze)
              else
                # Two separate code points
                [codepoint_1].pack('U'.freeze) + [codepoint_2].pack('U'.freeze)
              end
            else
              [codepoint_1].pack('U'.freeze)
            end
          else
            ESCAPES_REPLACE[matched_str]
          end
        end
        nil
      end

      # This is not used during parsing because the parser
      # doesn't actually need tokens.
      def self.tokenize(string)
        lexer = GraphQL::Language::Lexer.new(string)
        tokens = []
        while (token_name = lexer.advance)
          new_token = [
            token_name,
            lexer.line_number,
            lexer.column_number,
            lexer.debug_token_value(token_name),
          ]
          tokens << new_token
        end
        tokens
      end
    end
  end
end
