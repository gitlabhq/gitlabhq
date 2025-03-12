# frozen_string_literal: true

require "graphql"
require "graphql/c_parser/version"
require "graphql/graphql_c_parser_ext"

module GraphQL
  module CParser
    def self.parse(query_str, filename: nil, trace: GraphQL::Tracing::NullTrace, max_tokens: nil)
      Parser.parse(query_str, filename: filename, trace: trace, max_tokens: max_tokens)
    end

    def self.parse_file(filename)
      contents = File.read(filename)
      parse(contents, filename: filename)
    end

    def self.tokenize_with_c(str)
      reject_numbers_followed_by_names = GraphQL.respond_to?(:reject_numbers_followed_by_names) && GraphQL.reject_numbers_followed_by_names
      tokenize_with_c_internal(str, false, reject_numbers_followed_by_names)
    end

    def self.prepare_parse_error(message, parser)
      query_str = parser.query_string
      filename = parser.filename
      if message.start_with?("memory exhausted")
        return GraphQL::ParseError.new("This query is too large to execute.", nil, nil, query_str, filename: filename)
      end
      token = parser.tokens[parser.next_token_index - 1]
      if token
        # There might not be a token if it's a comments-only string
        line = token[1]
        col = token[2]
        if line && col
          location_str = " at [#{line}, #{col}]"
          if !message.include?(location_str)
            message += location_str
          end
        end

        if !message.include?("end of file")
          message.sub!(/, unexpected ([a-zA-Z ]+)(,| at)/, ", unexpected \\1 (#{token[3].inspect})\\2")
        end
      end

      GraphQL::ParseError.new(message, line, col, query_str, filename: filename)
    end

    def self.prepare_number_name_parse_error(line, col, query_str, number_part, name_part)
      raise GraphQL::ParseError.new("Name after number is not allowed (in `#{number_part}#{name_part}`)", line, col, query_str)
    end

    def self.prepare_bad_unicode_error(parser)
      token = parser.tokens[parser.next_token_index - 1]
      line = token[1]
      col = token[2]
      GraphQL::ParseError.new(
        "Parse error on bad Unicode escape sequence: #{token[3].inspect} (error) at [#{line}, #{col}]",
        line,
        col,
        parser.query_string,
        filename: parser.filename
      )
    end

    module Lexer
      def self.tokenize(graphql_string, intern_identifiers: false, max_tokens: nil)
        if !(graphql_string.encoding == Encoding::UTF_8 || graphql_string.ascii_only?)
          graphql_string = graphql_string.dup.force_encoding(Encoding::UTF_8)
        end
        if !graphql_string.valid_encoding?
          return [
            [
              :BAD_UNICODE_ESCAPE,
              1,
              1,
              graphql_string,
              241 # BAD_UNICODE_ESCAPE in lexer.rl
            ]
          ]
        end
        reject_numbers_followed_by_names = GraphQL.respond_to?(:reject_numbers_followed_by_names) && GraphQL.reject_numbers_followed_by_names
        # -1 indicates that there is no limit
        lexer_max_tokens = max_tokens.nil? ? -1 : max_tokens
        tokenize_with_c_internal(graphql_string, intern_identifiers, reject_numbers_followed_by_names, lexer_max_tokens)
      end
    end

    class Parser
      def self.parse(query_str, filename: nil, trace: GraphQL::Tracing::NullTrace, max_tokens: nil)
        self.new(query_str, filename, trace, max_tokens).result
      end

      def self.parse_file(filename)
        contents = File.read(filename)
        parse(contents, filename: filename)
      end

      def initialize(query_string, filename, trace, max_tokens)
        if query_string.nil?
          raise GraphQL::ParseError.new("No query string was present", nil, nil, query_string)
        end
        @query_string = query_string
        @filename = filename
        @tokens = nil
        @next_token_index = 0
        @result = nil
        @trace = trace
        @intern_identifiers = false
        @max_tokens = max_tokens
      end

      def result
        if @result.nil?
          @tokens = @trace.lex(query_string: @query_string) do
            GraphQL::CParser::Lexer.tokenize(@query_string, intern_identifiers: @intern_identifiers, max_tokens: @max_tokens)
          end
          @trace.parse(query_string: @query_string) do
            c_parse
            @result
          end
        end
        @result
      end

      def tokens_count
        result
        @tokens.length
      end

      attr_reader :tokens, :next_token_index, :query_string, :filename
    end

    class SchemaParser < Parser
      def initialize(*args)
        super
        @intern_identifiers = true
      end
    end
  end

  def self.scan_with_c(graphql_string)
    GraphQL::CParser::Lexer.tokenize(graphql_string)
  end

  def self.parse_with_c(string, filename: nil, trace: GraphQL::Tracing::NullTrace)
    if string.nil?
      raise GraphQL::ParseError.new("No query string was present", nil, nil, string)
    end
    document = GraphQL::CParser.parse(string, filename: filename, trace: trace)
    if document.definitions.size == 0
      raise GraphQL::ParseError.new("Unexpected end of document", 1, 1, string)
    end
    document
  end

  self.default_parser = GraphQL::CParser
end
