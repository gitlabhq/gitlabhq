# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Language::SanitizedPrinter do
  module SanitizeTest
    class Color < GraphQL::Schema::Enum
      value "RED"
      value "BLUE"
    end

    class Url < GraphQL::Schema::Scalar
    end

    class SimpleInput < GraphQL::Schema::InputObject
      argument :string, String
    end

    class ExampleInput < GraphQL::Schema::InputObject
      argument :string, String
      argument :id, ID
      argument :int, Int
      argument :float, Float
      argument :enum, Color
      argument :input_object, ExampleInput, required: false
      argument :url, Url
    end

    class Query < GraphQL::Schema::Object
      field :inputs, String, null: false do
        argument :string, String
        argument :id, ID
        argument :int, Int
        argument :float, Float
        argument :enum, Color
        argument :input_object, ExampleInput
        argument :url, Url
      end

      field :nested_array_inputs, String, null: false do
        argument :inputs, [SimpleInput]
      end

      field :colors, String, null: false do
        argument :colors, [Color]
      end

      field :strings, String, null: false do
        argument :strings, [String]
      end

      field :custom_scalar, String, null: false do
        argument :scalar, GraphQL::Types::JSON
      end
    end

    class Schema < GraphQL::Schema
      query(Query)
    end

    class CustomSanitizedPrinter < GraphQL::Language::SanitizedPrinter
      def redact_argument_value?(argument, value)
        true
      end

      def redacted_argument_value(argument)
        "<#{argument.graphql_name}-redacted>"
      end
    end

    class CustomSanitizedPrinterSchema < GraphQL::Schema
      query(Query)
      sanitized_printer(CustomSanitizedPrinter)
    end
  end

  def sanitize_string(query_string, inline_variables: true, **options)
    query = GraphQL::Query.new(
      SanitizeTest::Schema,
      query_string,
      **options
    )
    query.sanitized_query_string(inline_variables: inline_variables)
  end

  it "replaces strings with redacted" do
    query_str = '
    {
      inputs(
        string: "string",
        id: "id",
        int: 1,
        float: 2.0,
        url: "http://graphqliscool.com",
        enum: RED
        inputObject: {
          string: "string"
          id: "id"
          int: 1
          float: 2.0
          url: "http://graphqliscool.com"
          enum: RED
        }
      )
    }
    '

    expected_query_string = 'query {
  inputs(string: "<REDACTED>", id: "id", int: 1, float: 2.0, url: "<REDACTED>", enum: RED, inputObject: {string: "<REDACTED>", id: "id", int: 1, float: 2.0, url: "<REDACTED>", enum: RED})
}'
    assert_equal expected_query_string, sanitize_string(query_str)
  end

  it "inlines variables AND redacts their values" do
    query_str = '
    query($string1: String!, $string2: String = "str2", $inputObject: ExampleInput!) {
      inputs(
        string: $string1,
        id: "id1",
        int: 1,
        float: 1.0,
        url: "http://graphqliscool.com",
        enum: RED
        inputObject: {
          string: $string2
          id: "id2"
          int: 2
          float: 2.0
          url: "http://graphqliscool.com"
          enum: RED
          inputObject: $inputObject
        }
      )
    }
    '

    variables = {
      "string1" => "str1",
      "inputObject" => {
        "string" => "str3",
        "id" => "id3",
        "int" => 3,
        "float" => 3.3,
        "url" => "three.com",
        "enum" => "BLUE"
      }
    }

    expected_query_string = 'query {
  inputs(' +
    'string: "<REDACTED>", id: "id1", int: 1, float: 1.0, url: "<REDACTED>", enum: RED, inputObject: {' +
    'string: "<REDACTED>", id: "id2", int: 2, float: 2.0, url: "<REDACTED>", enum: RED, inputObject: {' +
    'string: "<REDACTED>", id: "id3", int: 3, float: 3.3, url: "<REDACTED>", enum: BLUE}})
}'
    assert_equal expected_query_string, sanitize_string(query_str, variables: variables)
  end

  it "doesn't inline variables when inline_variables is false" do
    query_str = '
    query($string1: String!, $string2: String = "str2", $inputObject: ExampleInput!, $strings: [String!]!) {
      inputs(
        string: $string1,
        id: "id1",
        int: 1,
        float: 1.0,
        url: "http://graphqliscool.com",
        enum: RED
        inputObject: {
          string: $string2
          id: "id2"
          int: 2
          float: 2.0
          url: "http://graphqliscool.com"
          enum: RED
          inputObject: $inputObject
        }
      )
      strings(strings: $strings)
    }
    '

    variables = {
      "string1" => "str1",
      "strings" => ["str1", "str2"],
      "inputObject" => {
        "string" => "str3",
        "id" => "id3",
        "int" => 3,
        "float" => 3.3,
        "url" => "three.com",
        "enum" => "BLUE"
      }
    }

    expected_query_string = 'query($string1: String!, $string2: String = "str2", $inputObject: ExampleInput!, $strings: [String!]!) {
  inputs(' +
      'string: $string1, id: "id1", int: 1, float: 1.0, url: "<REDACTED>", enum: RED, inputObject: {' +
      'string: $string2, id: "id2", int: 2, float: 2.0, url: "<REDACTED>", enum: RED, inputObject: $inputObject})
  strings(strings: $strings)
}'
    assert_equal expected_query_string, sanitize_string(query_str, variables: variables, inline_variables: false)
  end

  it "redacts from lists" do
    query_str_1 = '{ strings(strings: ["s1", "s2"]) }'
    query_str_2 = 'query($strings: [String!]!) { strings(strings: $strings) }'
    query_str_3 = 'query($string1: String!, $string2: String!) { strings(strings: [$string1, $string2]) }'
    expected_query_string = 'query {
  strings(strings: ["<REDACTED>", "<REDACTED>"])
}'

    assert_equal expected_query_string, sanitize_string(query_str_1)
    assert_equal expected_query_string, sanitize_string(query_str_2, variables: { "strings" => ["s1", "s2"] })
    assert_equal expected_query_string, sanitize_string(query_str_3, variables: { "string1" => "s1", "string2" => "s2" })
  end

  it "redacts from coerced lists" do
    query_str = '
    query {
      strings(strings: "s1")
      nestedArrayInputs(inputs: {string: "s2"})
    }
    '

    expected_query_string = 'query {
  strings(strings: ["<REDACTED>"])
  nestedArrayInputs(inputs: [{string: "<REDACTED>"}])
}'

    assert_equal expected_query_string, sanitize_string(query_str)
  end

  it "doesn't redact enums" do
    query_str_1 = '{ colors(colors: [RED, BLUE]) }'
    query_str_2 = 'query($colors: [Color!]!) { colors(colors: $colors) }'

    expected_query_string = 'query {
  colors(colors: [RED, BLUE])
}'

    assert_equal expected_query_string, sanitize_string(query_str_1)
    assert_equal expected_query_string, sanitize_string(query_str_2, variables: { "colors" => ["RED", "BLUE"] })
  end

  it "redacts strings from custom scalars" do
    query_str_1 = '
    query {
      s1: customScalar(scalar: "s1")
      s2: customScalar(scalar: 1)
      s3: customScalar(scalar: {string: "s2"})
      s4: customScalar(scalar: [{string: "s3"}])
    }
    '
    query_str_2 = '
    query($jsonString: JSON!, $jsonInt: JSON!, $jsonObject: JSON!, $jsonArray: JSON!) {
      s1: customScalar(scalar: $jsonString)
      s2: customScalar(scalar: $jsonInt)
      s3: customScalar(scalar: $jsonObject)
      s4: customScalar(scalar: $jsonArray)
    }
    '
    expected_query_string = 'query {
  s1: customScalar(scalar: "<REDACTED>")
  s2: customScalar(scalar: 1)
  s3: customScalar(scalar: {string: "<REDACTED>"})
  s4: customScalar(scalar: [{string: "<REDACTED>"}])
}'
    assert_equal expected_query_string, sanitize_string(query_str_1)
    variables = {
      "jsonString" => "s1",
      "jsonInt" => 1,
      "jsonObject" => {
        "string" => "s2"
      },
      "jsonArray" => [{
        "string" => "s3"
      }]
    }
    assert_equal expected_query_string, sanitize_string(query_str_2, variables: variables)
  end

  it "returns nil on invalid queries" do
    assert_nil sanitize_string "{ __typename "
  end

  it "provides hooks to override the redaction behavior" do
    query_str = '
    {
      inputs(
        string: "string",
        id: "id",
        int: 1,
        float: 2.0,
        url: "http://graphqliscool.com",
        enum: RED
        inputObject: {
          string: "string"
          id: "id"
          int: 1
          float: 2.0
          url: "http://graphqliscool.com"
          enum: RED
        }
      )
    }
    '

    expected_query_string = 'query {
  inputs(' +
      'string: <string-redacted>, id: <id-redacted>, int: <int-redacted>, float: <float-redacted>, url: <url-redacted>, enum: RED, inputObject: {' +
      'string: <string-redacted>, id: <id-redacted>, int: <int-redacted>, float: <float-redacted>, url: <url-redacted>, enum: RED})
}'
    query = GraphQL::Query.new(SanitizeTest::Schema, query_str)
    sanitized_query = SanitizeTest::CustomSanitizedPrinter.new(query).sanitized_query_string
    assert_equal expected_query_string, sanitized_query
  end

  it 'configure a custom printer from the schema' do
    query_str = '
    {
      inputs(
        string: "string",
        id: "id",
        int: 1,
        float: 2.0,
        url: "http://graphqliscool.com",
        enum: RED
        inputObject: {
          string: "string"
          id: "id"
          int: 1
          float: 2.0
          url: "http://graphqliscool.com"
          enum: RED
        }
      )
    }
    '

    expected_query_string = 'query {
  inputs(' +
      'string: <string-redacted>, id: <id-redacted>, int: <int-redacted>, float: <float-redacted>, url: <url-redacted>, enum: RED, inputObject: {' +
      'string: <string-redacted>, id: <id-redacted>, int: <int-redacted>, float: <float-redacted>, url: <url-redacted>, enum: RED})
}'
    query = GraphQL::Query.new(SanitizeTest::CustomSanitizedPrinterSchema, query_str)
    assert_equal expected_query_string, query.sanitized_query_string
  end

  it "properly prints enum variable default values" do
    class EnumSchema < GraphQL::Schema
      class Grouping < GraphQL::Schema::Enum
        value "DAY"
      end

      class Query < GraphQL::Schema::Object
        field :things, [String] do
          argument :group, Grouping
        end

        def things(group:)
          [group]
        end
      end

      query(Query)
    end
    query_string = <<~EOS
      query(
        $group: Grouping = DAY
      ) {
        things(group: $group)
      }
    EOS

    query = ::GraphQL::Query.new(EnumSchema, query_string)

    assert_equal ["DAY"], query.result["data"]["things"]
    expected_query_string = "query {\n  things(group: DAY)\n}"
    assert_equal expected_query_string, query.sanitized_query_string
  end
end
