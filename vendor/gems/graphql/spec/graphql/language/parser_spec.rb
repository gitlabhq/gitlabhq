# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Language::Parser do
  subject { GraphQL }

  it "returns an error on bad UTF-8" do
    err = assert_raises GraphQL::ParseError do
      subject.parse("{ foo(query: \"\xBF\") }")
    end
    expected_message = if USING_C_PARSER
      'Parse error on bad Unicode escape sequence: "{ foo(query: \"\xBF\") }" (error) at [1, 1]'
    else
      'Parse error on bad Unicode escape sequence'
    end
    assert_equal expected_message, err.message
  end

  it "rejects newlines in single-quoted strings unless escaped" do
    nl_query_string_1 = "{ doStuff(arg: \"
    abc\") }"
    nl_query_string_2 = "{ doStuff(arg: \"\rabc\") }"

    assert_raises(GraphQL::ParseError) {
      GraphQL.parse(nl_query_string_2)
    }
    assert_raises(GraphQL::ParseError) {
      GraphQL.parse(nl_query_string_2)
    }

    assert GraphQL.parse(GraphQL::Language.escape_single_quoted_newlines(nl_query_string_1))
    assert GraphQL.parse(GraphQL::Language.escape_single_quoted_newlines(nl_query_string_2))

    example_query_str = "mutation {
createRecord(data: {
  dynamicFields: { string_test: \"avenue 1st
2nd line\"}
})
  { id, dynamicFields }
}"
    assert_raises GraphQL::ParseError do
      GraphQL.parse(example_query_str)
    end

    escaped_query_str = GraphQL::Language.escape_single_quoted_newlines(example_query_str)

    expected_escaped_query_str = "mutation {
createRecord(data: {
  dynamicFields: { string_test: \"avenue 1st\\n2nd line\"}
})
  { id, dynamicFields }
}"
    assert_equal expected_escaped_query_str, escaped_query_str
    assert GraphQL.parse(escaped_query_str )
  end

  it "parses single-quoted strings with escaped newlines" do
    example_query_str = 'mutation {
createRecord(data: {
  dynamicFields: { string_test: "avenue 1st\n2nd line"}
})
  { id, dynamicFields }
}'
    assert GraphQL.parse(example_query_str)
  end

  it "can replace single-quoted newlines" do
    replacements = {
      "{ a(\"\n abc\n\") }" => '{ a("\\n abc\\n") }',
      "{ a(\"\r\n ab\rc\n\") }" => '{ a("\\r\\n ab\\rc\\n") }',
      "{ a(\"\n abc\n\") b(\"\n \\\"abc\n\") }" => '{ a("\\n abc\\n") b("\\n \\"abc\\n") }',
      # No modification to block strings:
      "{ a(\"\"\"\n abc\n\"\"\") }" => "{ a(\"\"\"\n abc\n\"\"\") }",
      "{ a(\"\"\"\r\n abc\r\n\"\"\") }" => "{ a(\"\"\"\r\n abc\r\n\"\"\") }",
    }

    replacements.each_with_index do |(before_str, after_str), idx|
      assert_equal after_str, GraphQL::Language.escape_single_quoted_newlines(before_str), "It works for example pair ##{idx + 1} (#{after_str})"
    end
  end

  it "can parse strings with null bytes" do
    assert GraphQL.parse("{ a(b: \"\\u0000\") }")
  end

  describe "when there are no selections" do
    it 'raises a ParseError' do
      assert_raises(GraphQL::ParseError) {
        GraphQL.parse('# comment')
      }
    end
  end

  it "parses directives on variable definitions" do
    ast = GraphQL.parse("query($var: Int = 1 @special) { do(something: $var) }")
    assert_equal ["special"], ast.definitions.first.variables.first.directives.map(&:name)
  end

  it "allows fragments, fields and arguments named null" do
    assert GraphQL.parse("{ field(null: false) ... null } fragment null on Query { null }")
  end

  it "allows fields, arguments, and enum values named on and directive" do
    assert GraphQL.parse("{ on(on: on) directive(directive: directive)}")
  end

  it "allows fields, arguments, and enum values named extend" do
    assert GraphQL.parse("{ extend(extend: extend) }")
  end

  it "allows fields, arguments, and enum values named type" do
    doc = GraphQL.parse("{ type(type: type) }")
    assert_instance_of GraphQL::Language::Nodes::Enum, doc.definitions.first.selections.first.arguments.first.value
  end

  it "handles invalid minus signs" do
    err = assert_raises GraphQL::ParseError do
      GraphQL.parse("{ a(b: -c) }")
    end
    expected_message = if USING_C_PARSER
      "syntax error, unexpected invalid token (\"-\") at [1, 8]"
    else
      "Expected type 'number', but it was malformed: \"-c\"."
    end
    assert_equal expected_message, err.message
  end

  it "handles invalid minus signs in variable default values" do
    err = assert_raises GraphQL::ParseError do
      GraphQL.parse("query($something: Int = -foo) { }")
    end
    expected_message = if USING_C_PARSER
      "syntax error, unexpected invalid token (\"-\") at [1, 25]"
    else
      "Expected type 'number', but it was malformed: \"-foo\"."
    end
    assert_equal expected_message, err.message
  end

  it "handles invalid minus signs in deeply nested input objects" do
    err = assert_raises GraphQL::ParseError do
      GraphQL.parse("{ doSomething(a: { b: { c: { d: -foo } } }) }")
    end
    expected_message = if USING_C_PARSER
      "syntax error, unexpected invalid token (\"-\") at [1, 33]"
    else
      "Expected type 'number', but it was malformed: \"-foo\"."
    end
    assert_equal expected_message, err.message
  end

  it "handles invalid minus signs in schema definitions" do
    err = assert_raises GraphQL::ParseError do
      GraphQL.parse("
      type Query {
        someField(a: Int = -foo): Int
      }
      ")
    end
    expected_message = if USING_C_PARSER
      "syntax error, unexpected invalid token (\"-\") at [3, 28]"
    else
      "Expected type 'number', but it was malformed: \"-foo\"."
    end
    assert_equal expected_message, err.message
  end

  it "handles invalid minus signs in list literals" do
    err = assert_raises GraphQL::ParseError do
      GraphQL.parse("{
        a1: a(b: [1,2,3])
        a2: a(b: [1, 2, -foo])
      }")
    end
    expected_message = if USING_C_PARSER
      "syntax error, unexpected invalid token (\"-\") at [3, 25]"
    else
      "Expected type 'number', but it was malformed: \"-foo\"."
    end
    assert_equal expected_message, err.message
  end

  it "allows operation names to match operation types" do
    doc = GraphQL.parse("query subscription { foo }")
    assert_equal "subscription", doc.definitions.first.name
  end

  it "raises an error for bad variables definition" do
    err = assert_raises(GraphQL::ParseError) do
      GraphQL.parse("query someQuery($someVariable: ,) { account { id } }")
    end
    expected_msg = if USING_C_PARSER
      "syntax error, unexpected RPAREN (\")\") at [1, 33]"
    else
      "Missing type definition for variable: $someVariable at [1, 33]"
    end

    assert_equal expected_msg, err.message
  end

  it "raises an error when unicode is used as names" do
    err = assert_raises(GraphQL::ParseError) {
      GraphQL.parse('query 😘 { a b }')
    }
    expected_msg = if USING_C_PARSER
      "syntax error, unexpected invalid token (\"\\xF0\"), expecting LCURLY at [1, 7]"
    else
      "Expected NAME, actual: UNKNOWN_CHAR (\"\\xF0\") at [1, 7]"
    end

    assert_equal expected_msg, err.message
  end

  it "can reject name start at the end of numbers" do
    prev_reject_numers_followed_by_names = GraphQL.reject_numbers_followed_by_names
    GraphQL.reject_numbers_followed_by_names = false
    assert GraphQL.parse("{ a(b: 123cde: 456)}"), "It accepts invalid constructions ... for now"
    GraphQL.reject_numbers_followed_by_names = true
    err = assert_raises GraphQL::ParseError do
      GraphQL.parse("{ a(b: 123cde: 456)}")
    end
    assert_equal "Name after number is not allowed (in `123cde`)", err.message

    err = assert_raises GraphQL::ParseError do
      GraphQL.parse("{ a(b: 12.3e5cfg: 456)}")
    end
    assert_equal "Name after number is not allowed (in `12.3e5cfg`)", err.message

    err2 = assert_raises GraphQL::ParseError do
      GraphQL.parse("query($input: SomeInput = { i1: 12i2: 15}) { t }")
    end
    assert_equal "Name after number is not allowed (in `12i2`)", err2.message
  ensure
    GraphQL.reject_numbers_followed_by_names = prev_reject_numers_followed_by_names
  end

  it "can replace namestart at the end of numbers" do
    expected_transforms = {
      "{ a(b: 123cde: 456)}"    => "{ a(b: 123 cde: 456)}",
      "{ a(b: 12.3e5cde: 456)}" => "{ a(b: 12.3e5 cde: 456)}",
      "{ a(b: 123e56cde: 456)}" => "{ a(b: 123e56 cde: 456)}",
      "{ a(b: 123e5) }" => nil,
      "{ a(b: 123e5 ) }" => nil,
      "{ a(b: 12.3e5) }" => nil,
      "{ a(b: 12.3e5 ) }" => nil,
      "query($obj: Input = { a: 1e5b: 2c: 3e-1}) { t }" => "query($obj: Input = { a: 1e5 b: 2 c: 3e-1}) { t }" ,
    }

    expected_transforms.each do |(start_str, finish_str)|
      changed_str = GraphQL::Language.add_space_between_numbers_and_names(start_str)
      if finish_str.nil?
        assert start_str.equal?(changed_str), "#{start_str.inspect} is unchanged (was: #{changed_str.inspect})"
      else
        assert_equal finish_str, changed_str, "Expected #{start_str.inspect} to become #{finish_str.inspect}"
        assert_equal finish_str, GraphQL::Language.add_space_between_numbers_and_names(finish_str), "Expected #{finish_str.inspect} not to change"
      end
    end
  end

  it "handles hyphens with errors" do
    err = assert_raises(GraphQL::ParseError) {
      GraphQL.parse("{ field(argument:a-b) }")
    }
    expected_msg = if USING_C_PARSER
      "syntax error, unexpected invalid token (\"-\") at [1, 19]"
    else
      "Expected type 'number', but it was malformed: \"-b\"."
    end

    assert_equal expected_msg, err.message
  end

  describe "anonymous fragment extension" do
    let(:document) { GraphQL.parse(query_string) }
    let(:query_string) {%|
      fragment on NestedType @or(something: "ok") {
        anotherNestedField
      }
    |}

    let(:fragment) { document.definitions.first }

    it "creates an anonymous fragment definition" do
      assert fragment.is_a?(GraphQL::Language::Nodes::FragmentDefinition)
      assert_nil fragment.name
      assert_equal 1, fragment.selections.length
      assert_equal "NestedType", fragment.type.name
      assert_equal 1, fragment.directives.length
      assert_equal [2, 7], fragment.position
    end
  end

  describe "string description" do
    it "is parsed for scalar definitions" do
      document = subject.parse <<-GRAPHQL
        "Thing description"
        scalar Thing
      GRAPHQL
      thing_defn = document.definitions[0]
      assert_equal "Thing", thing_defn.name
      assert_equal "Thing description", thing_defn.description
    end

    it "is parsed for object definitions, field definitions, and input value definitions" do
      document = subject.parse <<-GRAPHQL
      "Thing description"
      type Thing {
        "field description"
        field("arg description" arg: Stuff @yikes): Stuff @wow
      }
      GRAPHQL

      thing_defn = document.definitions[0]
      assert_equal "Thing", thing_defn.name
      assert_equal "Thing description", thing_defn.description

      field_defn = thing_defn.fields[0]
      assert_equal "field", field_defn.name
      assert_equal "field description", field_defn.description
      assert_equal ["wow"], field_defn.directives.map(&:name)

      arg_defn = field_defn.arguments[0]
      assert_equal "arg", arg_defn.name
      assert_equal "arg description", arg_defn.description
      assert_equal ["yikes"], arg_defn.directives.map(&:name)
    end

    it "is parsed for interface definitions" do
      document = subject.parse <<-GRAPHQL
        "Thing description"
        interface Thing {}
      GRAPHQL

      thing_defn = document.definitions[0]
      assert_equal "Thing", thing_defn.name
      assert_equal "Thing description", thing_defn.description
    end

    it "is parsed for union definitions" do
      document = subject.parse <<-GRAPHQL
        "Thing description"
        union Thing = Int | String
      GRAPHQL

      thing_defn = document.definitions[0]
      assert_equal "Thing", thing_defn.name
      assert_equal "Thing description", thing_defn.description
    end

    it "is parsed for enum definitions and enum value definitions" do
      document = subject.parse <<-GRAPHQL
        "Thing description"
        enum Thing {
          "VALUE description"
          VALUE
          type
        }
      GRAPHQL

      thing_defn = document.definitions[0]
      assert_equal "Thing", thing_defn.name
      assert_equal "Thing description", thing_defn.description

      value_defn = thing_defn.values[0]
      assert_equal "VALUE", value_defn.name
      assert_equal "VALUE description", value_defn.description

      value_defn = thing_defn.values[1]
      assert_equal "type", value_defn.name
      assert_nil value_defn.description
    end

    it "is parsed for directive definitions" do
      document = subject.parse <<-GRAPHQL
      "thing description" directive @thing repeatable on FIELD
      GRAPHQL

      thing_defn = document.definitions[0]
      assert_equal "thing", thing_defn.name
      assert_equal true, thing_defn.repeatable
      assert_equal "thing description", thing_defn.description
    end
  end

  it "parses query without arguments" do
    strings = [
      "{ field { inner } }"
    ]
    strings.each do |query_str|
      doc = subject.parse(query_str)
      field = doc.definitions.first.selections.first
      assert_equal 0, field.arguments.length
      assert_equal 1, field.selections.length
    end
  end

  it "parses backslashes in arguments" do
    document = subject.parse <<-GRAPHQL
      query {
        item(text: "a", otherText: "b\\\\") {
          text
          otherText
        }
      }
    GRAPHQL
    assert_equal "b\\", document.definitions[0].selections[0].arguments[1].value
  end

  it "parses backslashes in non-last arguments" do
    document = subject.parse <<-GRAPHQL
      query {
        item(text: "b\\\\", otherText: "a") {
          text
          otherText
        }
      }
    GRAPHQL
    assert_equal "b\\", document.definitions[0].selections[0].arguments[0].value
  end

  it "parses a great big object type" do
    str = <<-GRAPHQL
"""
Query root of the system
"""
type Query {
  allAnimal: [Animal]!
  allAnimalAsCow: [AnimalAsCow]!
  allDairy(executionErrorAtIndex: Int): [DairyProduct]
  allEdible: [Edible]
  allEdibleAsMilk: [EdibleAsMilk]

  """
  Find a Dummy::Cheese by id
  """
  cheese(id: Int!): Cheese

  """
  Find the only Dummy::Cow
  """
  cow: Cow

  """
  Find the only Dummy::Dairy
  """
  dairy: Dairy
  deepNonNull: DeepNonNull!

  """
  Raise an error
  """
  error: String
  executionError: String
  executionErrorWithExtensions: Int
  executionErrorWithOptions: Int

  """
  My favorite food
  """
  favoriteEdible: Edible

  """
  Cheese from source
  """
  fromSource(oldSource: String @deprecated, source: DairyAnimal = COW): [Cheese]
  hugeInteger: Int
  maybeNull: MaybeNull

  """
  Find a Dummy::Milk by id
  """
  milk(id: ID!): Milk
  multipleErrorsOnNonNullableField: String!
  multipleErrorsOnNonNullableListField: [String!]!
  root: String

  """
  Find dairy products matching a description
  """
  searchDairy(expiresAfter: Time, oldProduct: [DairyProductInput!] @deprecated, product: [DairyProductInput] = [{source: SHEEP}], productIds: [String!] @deprecated, singleProduct: DairyProductInput): DairyProduct!
  tracingScalar: TracingScalar
  valueWithExecutionError: Int!
}
    GRAPHQL

    doc = subject.parse(str)
    assert_equal str.chomp, doc.to_query_string
  end

  it "parses input types" do
    doc = subject.parse <<~GRAPHQL
input ReplaceValuesInput {
  values: [Int!]!
}
GRAPHQL
    input_t = doc.definitions.first
    assert_equal "ReplaceValuesInput", input_t.name
    assert_equal ["values"], input_t.fields.map(&:name)
    assert_equal [nil], input_t.fields.map(&:description)
  end

  it "parses the test schema" do
    schema = Dummy::Schema
    schema_string = GraphQL::Schema::Printer.print_schema(schema)
    document = subject.parse(schema_string)
    assert_equal schema_string.chomp, document.to_query_string
  end

  it "parses various implements" do
    doc = subject.parse <<-GRAPHQL
    type Milk implements AnimalProduct & Edible & EdibleAsMilk & LocalProduct {
      executionError: String
    }
    GRAPHQL
    expected_names = ["AnimalProduct", "Edible", "EdibleAsMilk", "LocalProduct"]

    assert_equal expected_names, doc.definitions.first.interfaces.map(&:name)
    doc2 = subject.parse <<-GRAPHQL
    type Milk implements & AnimalProduct & Edible & EdibleAsMilk & LocalProduct {
      executionError: String
    }
    GRAPHQL

    assert_equal expected_names, doc2.definitions.first.interfaces.map(&:name)

    doc3 = subject.parse <<-GRAPHQL
    type Milk implements AnimalProduct, Edible, EdibleAsMilk  LocalProduct {
      executionError: String
    }
    GRAPHQL
    assert_equal expected_names, doc3.definitions.first.interfaces.map(&:name)
  end

  it "parses union types with leading pipes" do
    doc = subject.parse("union U =\n  | A\n  | B")
    assert_equal ["A", "B"], doc.definitions.first.types.map(&:name)
  end

  describe "parse errors" do
    it "raises parse errors for nil" do
      assert_raises(GraphQL::ParseError) {
        GraphQL.parse(nil)
      }
    end

    it 'raises parse errors for empty argument sets' do
      # Regression spec from https://github.com/rmosolgo/graphql-ruby/pull/2344
      query_with_empty_arguments = '{ node() { id } }'

      assert_raises(GraphQL::ParseError) {
        subject.parse(query_with_empty_arguments)
      }
    end

    it 'raises parse errors for argument sets without value' do
      # Regression spec from https://github.com/rmosolgo/graphql-ruby/pull/2344
      query_with_malformed_argument_value = '{ node(id:) { name } }'

      assert_raises(GraphQL::ParseError) {
        pp subject.parse(query_with_malformed_argument_value)
      }
    end
  end

  describe ".parse_file" do
    it "assigns filename to all nodes" do
      example_filename = "spec/support/parser/filename_example.graphql"
      doc = GraphQL.parse_file(example_filename)
      assert_equal example_filename, doc.filename
      field = doc.definitions[0].selections[0].selections[0]
      assert_equal example_filename, field.filename
    end

    it "raises errors with filename" do
      error_filename = "spec/support/parser/filename_example_error_1.graphql"
      err = assert_raises(GraphQL::ParseError) {
        GraphQL.parse_file(error_filename)
      }

      assert_includes err.message, error_filename

      error_filename_2 = "spec/support/parser/filename_example_error_2.graphql"
      err_2 = assert_raises(GraphQL::ParseError) {
        GraphQL.parse_file(error_filename_2)
      }

      assert_includes err_2.message, error_filename_2
      assert_includes err_2.message, "3, 11"

    end
  end

  describe "#tokens_count" do
    it "counts parsed token" do
      str = "type Query { f1: Int }"
      parser = GraphQL::Language::Parser.new(str)

      assert_equal 7, parser.tokens_count
    end
  end

  module ParserTrace
    TRACES = []
    def parse(query_string:)
      TRACES << (trace = { key: "parse", query_string: query_string })
      result = super
      trace[:result] = result
      result
    end

    def lex(query_string:)
      TRACES << (trace = { key: "lex", query_string: query_string })
      result = super
      trace[:result] = result
      result
    end

    def self.clear
      TRACES.clear
    end

    def self.traces
      TRACES
    end
  end

  it "serves traces" do
    ParserTrace.clear
    schema = Class.new(GraphQL::Schema) do
      trace_with(ParserTrace)
    end
    query = GraphQL::Query.new(schema, "{ t: __typename }")
    subject.parse("{ t: __typename }", trace: query.current_trace)
    traces = ParserTrace.traces
    expected_traces = if USING_C_PARSER
      2
    else
      1
    end
    assert_equal expected_traces, traces.length
    lex_trace, parse_trace = traces

    if USING_C_PARSER
      assert_equal "{ t: __typename }", lex_trace[:query_string]
      assert_equal "lex", lex_trace[:key]
      assert_instance_of Array, lex_trace[:result]
    else
      parse_trace = lex_trace
    end

    assert_equal "{ t: __typename }", parse_trace[:query_string]
    assert_equal "parse", parse_trace[:key]
    assert_instance_of GraphQL::Language::Nodes::Document, parse_trace[:result]
  end
end
