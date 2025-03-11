# frozen_string_literal: true
module TokenMethods
  refine Array do
    def name
      self[0]
    end

    def value
      self[3]
    end

    def to_s
      self[3]
    end

    def line
      self[1]
    end

    def col
      self[2]
    end

    def inspect
      "(#{name} #{value.inspect} [#{line}:#{col}])"
    end
  end
end

using TokenMethods

module LexerExamples
  def self.included(child_mod)
    child_mod.module_eval do
      describe ".tokenize" do
        let(:query_string) {%|
          {
            query getCheese {
              cheese(id: 1) {
                ... cheeseFields
              }
            }
          }
        |}
        let(:tokens) { subject.tokenize(query_string) }

        it "force encodes to utf-8" do
          # string that will be invalid utf-8 once force encoded
          string = "vandflyver \xC5rhus".dup.force_encoding("ASCII-8BIT")
          assert_bad_unicode(string)
        end

        it "makes utf-8 arguments named type" do
          str = "{ a(type: 1) }"
          tokens = subject.tokenize(str)
          assert_equal Encoding::UTF_8, tokens[2].value.encoding
        end

        it "handles integers with a leading zero" do
          tokens = subject.tokenize("{ a(id: 04) }")
          assert_equal :INT, tokens[5].name
        end

        it "allows escaped quotes in strings" do
          tokens = subject.tokenize('"a\\"b""c"')
          assert_equal 'a"b', tokens[0].value
          assert_equal 'c', tokens[1].value
        end

        it "handles escaped backslashes before escaped quotes" do
          tokens = subject.tokenize('text: "b\\\\", otherText: "a"')
          assert_equal ['text', ':', 'b\\', 'otherText', ':', 'a',], tokens.map(&:value)
        end

        describe "block strings" do
          let(:query_string) { %|{ a(b: """\nc\n \\""" d\n""" """""e""""")}|}

          it "tokenizes them" do
            assert_equal "c\n \\\"\"\" d", tokens[5].value
            assert_equal "\"\"e\"\"", tokens[6].value
          end

          it "tokenizes 10 quote edge case correctly" do
            tokens = subject.tokenize('""""""""""')
            assert_equal '""', tokens[0].value # first 8 quotes are a valid block string """"""""
            assert_equal '', tokens[1].value # last 2 quotes are a valid string ""
          end

          it "tokenizes with nested single quote strings correctly" do
            tokens = subject.tokenize('"""{"x"}"""')
            assert_equal '{"x"}', tokens[0].value

            tokens = subject.tokenize('"""{"foo":"bar"}"""')
            assert_equal '{"foo":"bar"}', tokens[0].value
          end

          it "tokenizes empty block strings correctly" do
            empty_block_string = '""""""'
            tokens = subject.tokenize(empty_block_string)

            assert_equal '', tokens[0].value
          end

          it "tokenizes escaped backslashes at the end of blocks" do
            query_str = <<-GRAPHQL
text: """b\\\\""", otherText: "a"
GRAPHQL

            tokens = subject.tokenize(query_str)
            assert_equal ['text', ':', 'b\\\\', 'otherText', ':', 'a',], tokens.map(&:value)
          end
        end

        it "unescapes escaped characters" do
          assert_equal "\" \\ / \b \f \n \r \t", subject.tokenize('"\\" \\\\ \\/ \\b \\f \\n \\r \\t"').first.to_s
        end

        it "unescapes escaped unicode characters" do
          assert_equal "\t", subject.tokenize('"\\u0009"').first.to_s
          assert_equal "\t", subject.tokenize('"\\u{0009}"').first.to_s
          assert_equal "𐘑", subject.tokenize('"\\u{10611}"').first.to_s
          assert_equal "💩", subject.tokenize('"\\u{1F4A9}"').first.to_s
          assert_equal "💩", subject.tokenize('"\\uD83D\\uDCA9"').first.to_s
        end

        it "accepts the full range of unicode" do
          assert_equal "💩", subject.tokenize('"💩"').first.to_s
          assert_equal "⌱", subject.tokenize('"⌱"').first.to_s
          assert_equal "🂡\n🂢", subject.tokenize('"""🂡
    🂢"""').first.to_s
        end

        it "doesn't accept unicode outside strings or comments" do
          assert_equal :UNKNOWN_CHAR, subject.tokenize('😘 ').first.name
        end

        it "rejects bad unicode, even when there's good unicode in the string" do
          assert_bad_unicode('"\\u0XXF \\u0009"', "Bad unicode escape in \"\\\\u0XXF \\\\u0009\"")
        end

        it "rejects truly invalid UTF-8 bytes" do
          error_filename = "spec/support/parser/filename_example_invalid_utf8.graphql"
          text = File.read(error_filename)
          assert_bad_unicode(text)
        end

        it "rejects unicode that's well-formed but results in invalidly-encoded strings" do
          # when the string here gets tokenized into an actual `:STRING`, it results in `valid_encoding?` being false for
          # the ruby string so application code usually blows up trying to manipulate it
          text1 = '"\\udc00\\udf2c"'
          assert_bad_unicode(text1, 'Bad unicode escape in "\\xED\\xB0\\x80\\xED\\xBC\\xAC"')
          text2 = '"\\u{dc00}\\u{df2c}"'
          assert_bad_unicode(text2, 'Bad unicode escape in "\\xED\\xB0\\x80\\xED\\xBC\\xAC"')
        end

        it "counts string position properly" do
          tokens = subject.tokenize('{ a(b: "c")}')
          str_token = tokens[5]
          assert_equal :STRING, str_token.name
          assert_equal "c", str_token.value
          assert_equal 8, str_token.col
          assert_equal '(STRING "c" [1:8])', str_token.inspect
          rparen_token = tokens[6]
          assert_equal '(RPAREN ")" [1:11])', rparen_token.inspect
        end

        it "tokenizes block quotes with triple quotes correctly" do
          doc = <<-eos
"""

string with \\"""

"""
          eos
          tokens = subject.tokenize doc
          token = tokens.first
          assert_equal :STRING, token.name
          assert_equal 'string with \"""', token.value
        end

        it "counts block string line properly" do
          str = <<-GRAPHQL
          """
          Here is a
          multiline description
          """
          type Query {
            a: B
          }

          "Here's another description"

          type B {
            a: B
          }

          """
          And another
          multiline description
          """


          type C {
            a: B
          }
          GRAPHQL

          tokens = subject.tokenize(str)

          string_tok, type_keyword_tok, query_name_tok,
            _curly, _ident, _colon, _ident, _curly,
            string_tok_2, type_keyword_tok_2, b_name_tok,
            _curly, _ident, _colon, _ident, _curly,
            string_tok_3, type_keyword_tok_3, c_name_tok = tokens

          assert_equal 1, string_tok.line
          assert_equal 5, type_keyword_tok.line
          assert_equal 5, query_name_tok.line

          # Make sure it handles the empty spaces, too
          assert_equal 9, string_tok_2.line
          assert_equal 11, type_keyword_tok_2.line
          assert_equal 11, b_name_tok.line

          assert_equal 15, string_tok_3.line
          assert_equal 21, type_keyword_tok_3.line
          assert_equal 21, c_name_tok.line
        end

        it "halts after max_tokens" do
          query_type = Class.new(GraphQL::Schema::Object) do
            graphql_name "Query"
            field :x, Integer
          end
          parent_schema = Class.new(GraphQL::Schema) do
            query(query_type)
          end

          child_schema = Class.new(parent_schema) do
            max_query_string_tokens(5000)
          end

          assert_nil parent_schema.max_query_string_tokens
          assert_equal 5000, child_schema.max_query_string_tokens

          query_str = 3_000.times.map { |n| "query Q#{n} { __typename }" }.join("\n")
          assert_equal 15_000, subject.tokenize(query_str).size
          assert GraphQL.parse(query_str)
          result = child_schema.execute(query_str)
          assert_equal ["This query is too large to execute."], result["errors"].map { |e| e["message"] }

          result2 = parent_schema.execute(query_str)
          assert_equal ["An operation name is required"], result2["errors"].map { |e| e["message"] }
        end
      end
    end
  end
end
