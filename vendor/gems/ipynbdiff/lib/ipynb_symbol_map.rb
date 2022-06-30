# frozen_string_literal: true

module IpynbDiff
  class InvalidTokenError < StandardError
  end

  # Creates a symbol map for a ipynb file (JSON format)
  class IpynbSymbolMap
    class << self
      def parse(notebook, objects_to_ignore = [])
        IpynbSymbolMap.new(notebook, objects_to_ignore).parse('')
      end
    end

    attr_reader :current_line, :char_idx, :results

    WHITESPACE_CHARS = ["\t", "\r", ' ', "\n"].freeze

    VALUE_STOPPERS = [',', '[', ']', '{', '}', *WHITESPACE_CHARS].freeze

    def initialize(notebook, objects_to_ignore = [])
      @chars = notebook.chars
      @current_line = 0
      @char_idx = 0
      @results = {}
      @objects_to_ignore = objects_to_ignore
    end

    def parse(prefix = '.')
      raise_if_file_ended

      skip_whitespaces

      if (c = current_char) == '"'
        parse_string
      elsif c == '['
        parse_array(prefix)
      elsif c == '{'
        parse_object(prefix)
      else
        parse_value
      end

      results
    end

    def parse_array(prefix)
      # [1, 2, {"some": "object"}, [1]]

      i = 0

      current_should_be '['

      loop do
        raise_if_file_ended

        break if skip_beginning(']')

        new_prefix = "#{prefix}.#{i}"

        add_result(new_prefix, current_line)

        parse(new_prefix)

        i += 1
      end
    end

    def parse_object(prefix)
      # {"name":"value", "another_name": [1, 2, 3]}

      current_should_be '{'

      loop do
        raise_if_file_ended

        break if skip_beginning('}')

        prop_name = parse_string(return_value: true)

        next_and_skip_whitespaces

        current_should_be ':'

        next_and_skip_whitespaces

        if @objects_to_ignore.include? prop_name
          skip
        else
          new_prefix = "#{prefix}.#{prop_name}"

          add_result(new_prefix, current_line)

          parse(new_prefix)
        end
      end
    end

    def parse_string(return_value: false)
      current_should_be '"'
      init_idx = @char_idx

      loop do
        increment_char_index

        raise_if_file_ended

        if current_char == '"' && !prev_backslash?
          init_idx += 1
          break
        end
      end

      @chars[init_idx...@char_idx].join if return_value
    end

    def add_result(key, line_number)
      @results[key] = line_number
    end

    def parse_value
      increment_char_index until raise_if_file_ended || VALUE_STOPPERS.include?(current_char)
    end

    def skip_whitespaces
      while WHITESPACE_CHARS.include?(current_char)
        raise_if_file_ended
        check_for_new_line
        increment_char_index
      end
    end

    def increment_char_index
      @char_idx += 1
    end

    def next_and_skip_whitespaces
      increment_char_index
      skip_whitespaces
    end

    def current_char
      raise_if_file_ended

      @chars[@char_idx]
    end

    def prev_backslash?
      @chars[@char_idx - 1] == '\\' && @chars[@char_idx - 2] != '\\'
    end

    def current_should_be(another_char)
      raise InvalidTokenError unless current_char == another_char
    end

    def check_for_new_line
      @current_line += 1 if current_char == "\n"
    end

    def raise_if_file_ended
      @char_idx >= @chars.size && raise(InvalidTokenError)
    end

    def skip
      raise_if_file_ended

      skip_whitespaces

      if (c = current_char) == '"'
        parse_string
      elsif c == '['
        skip_array
      elsif c == '{'
        skip_object
      else
        parse_value
      end
    end

    def skip_array
      loop do
        raise_if_file_ended

        break if skip_beginning(']')

        skip
      end
    end

    def skip_object
      loop do
        raise_if_file_ended

        break if skip_beginning('}')

        parse_string

        next_and_skip_whitespaces

        current_should_be ':'

        next_and_skip_whitespaces

        skip
      end
    end

    def skip_beginning(closing_char)
      check_for_new_line

      next_and_skip_whitespaces

      return true if current_char == closing_char

      next_and_skip_whitespaces if current_char == ','
    end
  end
end
