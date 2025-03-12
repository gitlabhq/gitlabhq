# frozen_string_literal: true
require "spec_helper"
require_relative "./lexer_examples"

if defined?(GraphQL::CParser::Lexer)
  describe GraphQL::CParser::Lexer do
    subject { GraphQL::CParser::Lexer }

    def assert_bad_unicode(string, _message = nil)
      assert_equal :BAD_UNICODE_ESCAPE, subject.tokenize(string).first[0]
    end

    it "makes tokens like the other lexer" do
      str = "{ f1(type: \"str\") ...F2 }\nfragment F2 on SomeType { f2 }"
      tokens = GraphQL.scan_with_c(str).map { |t| [*t.first(4), t[3].encoding] }
      old_tokens = GraphQL.scan_with_ruby(str).map { |t| [*t, t[3].encoding] }

      assert_equal [
        [:LCURLY, 1, 1, "{", Encoding::UTF_8],
        [:IDENTIFIER, 1, 3, "f1", Encoding::UTF_8],
        [:LPAREN, 1, 5, "(", Encoding::UTF_8],
        [:TYPE, 1, 6, "type", Encoding::UTF_8],
        [:COLON, 1, 10, ":", Encoding::UTF_8],
        [:STRING, 1, 12, "str", Encoding::UTF_8],
        [:RPAREN, 1, 17, ")", Encoding::UTF_8],
        [:ELLIPSIS, 1, 19, "...", Encoding::UTF_8],
        [:IDENTIFIER, 1, 22, "F2", Encoding::UTF_8],
        [:RCURLY, 1, 25, "}", Encoding::UTF_8],
        [:FRAGMENT, 2, 1, "fragment", Encoding::UTF_8],
        [:IDENTIFIER, 2, 10, "F2", Encoding::UTF_8],
        [:ON, 2, 13, "on", Encoding::UTF_8],
        [:IDENTIFIER, 2, 16, "SomeType", Encoding::UTF_8],
        [:LCURLY, 2, 25, "{", Encoding::UTF_8],
        [:IDENTIFIER, 2, 27, "f2", Encoding::UTF_8],
        [:RCURLY, 2, 30, "}", Encoding::UTF_8]
      ], tokens
      assert_equal(old_tokens, tokens)
    end

    it "makes frozen strings when using SchemaParser" do
      str = "type Query { f1: Int }"
      schema_ast = GraphQL::CParser::SchemaParser.new(str, nil, GraphQL::Tracing::NullTrace, nil).result
      default_ast = GraphQL::CParser::Parser.new(str, nil, GraphQL::Tracing::NullTrace, nil).result

      # Equivalent ASTs:
      assert_equal schema_ast, default_ast

      # But this one is frozen:
      assert_equal "Query", schema_ast.definitions.first.name
      assert schema_ast.definitions.first.name.frozen?

      # And this one isn't:
      assert_equal "Query", default_ast.definitions.first.name
      refute default_ast.definitions.first.name.frozen?
    end

    it "exposes tokens_count" do
      str = "type Query { f1: Int }"
      parser = GraphQL::CParser::Parser.new(str, nil, GraphQL::Tracing::NullTrace, nil)

      assert_equal 7, parser.tokens_count
    end

    include LexerExamples
  end
end
