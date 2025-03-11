# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Loader do
  Boolean = "Boolean"
  ID = "ID"
  Int = "Int"

  let(:schema) {
    node_type = Module.new do
      include GraphQL::Schema::Interface
      graphql_name "Node"

      field :id, ID, null: false
    end

    choice_type = Class.new(GraphQL::Schema::Enum) do
      graphql_name "Choice"

      value "FOO", value: :foo
      value "BAR", deprecation_reason: "Don't use BAR"
      value "foo"
    end

    sub_input_type = Class.new(GraphQL::Schema::InputObject) do
      graphql_name "Sub"
      argument :string, String, required: false
    end

    big_int_type = Class.new(GraphQL::Schema::Scalar) do
      graphql_name "BigInt"
      specified_by_url "https://bigint.com"
      def self.coerce_input(value, _ctx)
        value =~ /\d+/ ? Integer(value) : nil
      end

      def self.coerce_result(value, _ctx)
        value.to_s
      end
    end

    variant_input_type = Class.new(GraphQL::Schema::InputObject) do
      graphql_name "Varied"
      argument :id, ID, required: false
      argument :int, Int, required: false
      argument :bigint, big_int_type, required: false, default_value: 2**54
      argument :float, Float, required: false
      argument :bool, Boolean, required: false
      argument :enum, choice_type, required: false
      argument :sub, [sub_input_type], required: false
      argument :deprecated_arg, String, required: false, deprecation_reason: "Don't use Varied.deprecatedArg"
    end

    variant_input_type_with_nulls = Class.new(GraphQL::Schema::InputObject) do
      graphql_name "VariedWithNulls"
      argument :id, ID, required: false, default_value: nil
      argument :int, Int, required: false, default_value: nil
      argument :bigint, big_int_type, required: false, default_value: nil
      argument :float, Float, required: false, default_value: nil
      argument :bool, Boolean, required: false, default_value: nil
      argument :enum, choice_type, required: false, default_value: nil
      argument :sub, [sub_input_type], required: false, default_value: nil
    end

    comment_type = Class.new(GraphQL::Schema::Object) do
      graphql_name "Comment"
      description "A blog comment"
      implements node_type

      field :body, String, null: false

      field :field_with_arg, Int do
        argument :bigint, big_int_type, default_value: 2**54, required: false
      end
    end

    media_type = Module.new do
      include GraphQL::Schema::Interface

      graphql_name "Media"
      description "!!!"
      field :type, String, null: false
    end

    video_type = Class.new(GraphQL::Schema::Object) do
      graphql_name "Video"
      implements media_type
    end

    audio_type = Class.new(GraphQL::Schema::Object) do
      graphql_name "Audio"
      implements media_type
    end

    post_type = Class.new(GraphQL::Schema::Object) do
      graphql_name "Post"
      description "A blog post"

      field :id, ID, null: false
      field :title, String, null: false
      field :summary, String, deprecation_reason: "Don't use Post.summary"
      field :body, String, null: false
      field :comments, [comment_type]
      field :attachment, media_type
    end

    content_type = Class.new(GraphQL::Schema::Union) do
      graphql_name "Content"
      description "A post or comment"
      possible_types post_type, comment_type
    end

    query_root = Class.new(GraphQL::Schema::Object) do
      graphql_name "Query"
      description "The query root of this schema"

      field :post, post_type do
        argument :id, ID
        argument :varied, variant_input_type, required: false, default_value: { id: "123", int: 234, float: 2.3, enum: :foo, sub: [{ string: "str" }] }
        argument :variedWithNull, variant_input_type_with_nulls, required: false, default_value: { id: nil, int: nil, float: nil, enum: nil, sub: nil, bigint: nil, bool: nil }
        argument :variedArray, [variant_input_type], required: false, default_value: [{ id: "123", int: 234, float: 2.3, enum: :foo, sub: [{ string: "str" }] }]
        argument :enum, choice_type, required: false, default_value: :foo
        argument :array, [String], required: false, default_value: ["foo", "bar"]
        argument :deprecated_arg, String, required: false, deprecation_reason: "Don't use Varied.deprecatedArg"
      end

      field :content, content_type
    end

    ping_mutation = Class.new(GraphQL::Schema::RelayClassicMutation) do
      graphql_name "Ping"
    end

    mutation_root = Class.new(GraphQL::Schema::Object) do
      graphql_name "Mutation"
      field :ping, mutation: ping_mutation
    end

    repeatable_transform = Class.new(GraphQL::Schema::Directive::Transform) do
      graphql_name "repeatableTransform"
      repeatable(true)
    end

    Class.new(GraphQL::Schema) do
      query query_root
      mutation mutation_root
      orphan_types audio_type, video_type
      description "A schema for loader_spec.rb"
      directives repeatable_transform
    end
  }

  let(:schema_json) {
    schema.execute(GraphQL::Introspection.query(include_deprecated_args: true, include_schema_description: true, include_specified_by_url: true, include_is_repeatable: true))
  }

  describe "load" do
    def assert_equal_or_nil(expected_value, actual_value)
      if expected_value.nil?
        assert_nil actual_value
      else
        assert_equal expected_value, actual_value
      end
    end
    def assert_deep_equal(expected_type, actual_type)
      if actual_type.is_a?(Array)
        actual_type.each_with_index do |obj, index|
          assert_deep_equal expected_type[index], obj
        end
      elsif actual_type.is_a?(GraphQL::Schema::Field)
        assert_equal_or_nil expected_type.graphql_name, actual_type.graphql_name
        assert_equal_or_nil expected_type.description, actual_type.description
        assert_equal_or_nil expected_type.deprecation_reason, actual_type.deprecation_reason
        assert_equal_or_nil expected_type.arguments.keys.sort, actual_type.arguments.keys.sort
        assert_deep_equal expected_type.arguments.values.sort_by(&:graphql_name), actual_type.arguments.values.sort_by(&:graphql_name)
      elsif actual_type.is_a?(GraphQL::Schema::EnumValue)
        assert_equal_or_nil expected_type.graphql_name, actual_type.graphql_name
        assert_equal_or_nil expected_type.description, actual_type.description
        assert_equal_or_nil expected_type.deprecation_reason, actual_type.deprecation_reason
      elsif actual_type.is_a?(GraphQL::Schema::Argument)
        assert_equal_or_nil expected_type.graphql_name, actual_type.graphql_name
        assert_equal_or_nil expected_type.description, actual_type.description
        assert_equal_or_nil expected_type.deprecation_reason, actual_type.deprecation_reason
        assert_deep_equal expected_type.type, actual_type.type
      elsif actual_type.is_a?(GraphQL::Schema::NonNull) || actual_type.is_a?(GraphQL::Schema::List)
        assert_equal_or_nil expected_type.class, actual_type.class
        assert_deep_equal expected_type.of_type, actual_type.of_type
      elsif actual_type < GraphQL::Schema
        assert_equal_or_nil expected_type.query.graphql_name, actual_type.query.graphql_name
        assert_equal_or_nil expected_type.mutation.graphql_name, actual_type.mutation.graphql_name
        assert_equal_or_nil expected_type.directives.keys.sort, actual_type.directives.keys.sort
        assert_deep_equal expected_type.directives.values.sort_by(&:graphql_name), actual_type.directives.values.sort_by(&:graphql_name)
        assert_equal_or_nil expected_type.types.keys.sort, actual_type.types.keys.sort
        assert_deep_equal expected_type.types.values.sort_by(&:graphql_name), actual_type.types.values.sort_by(&:graphql_name)
        assert_equal_or_nil expected_type.description, actual_type.description
      elsif actual_type < GraphQL::Schema::Object
        assert_equal_or_nil expected_type.graphql_name, actual_type.graphql_name
        assert_equal_or_nil expected_type.description, actual_type.description
        assert_equal_or_nil expected_type.interfaces.map(&:graphql_name).sort, actual_type.interfaces.map(&:graphql_name).sort
        assert_deep_equal expected_type.interfaces.sort_by(&:graphql_name), actual_type.interfaces.sort_by(&:graphql_name)
        assert_equal_or_nil expected_type.fields.keys.sort, actual_type.fields.keys.sort
        assert_deep_equal expected_type.fields.values.sort_by(&:graphql_name), actual_type.fields.values.sort_by(&:graphql_name)
      elsif actual_type < GraphQL::Schema::Interface
        assert_equal_or_nil expected_type.graphql_name, actual_type.graphql_name
        assert_equal_or_nil expected_type.description, actual_type.description
        assert_equal_or_nil expected_type.fields.keys.sort, actual_type.fields.keys.sort
        assert_deep_equal expected_type.fields.values.sort_by(&:graphql_name), actual_type.fields.values.sort_by(&:graphql_name)
      elsif actual_type < GraphQL::Schema::Union
        assert_equal_or_nil expected_type.graphql_name, actual_type.graphql_name
        assert_equal_or_nil expected_type.description, actual_type.description
        assert_equal_or_nil expected_type.possible_types.map(&:graphql_name).sort, actual_type.possible_types.map(&:graphql_name).sort
        assert_deep_equal expected_type.possible_types.sort_by(&:graphql_name), actual_type.possible_types.sort_by(&:graphql_name)
      elsif actual_type < GraphQL::Schema::Scalar
        assert_equal_or_nil expected_type.graphql_name, actual_type.graphql_name
        assert_equal_or_nil expected_type.specified_by_url, actual_type.specified_by_url
      elsif actual_type < GraphQL::Schema::Enum
        assert_equal_or_nil expected_type.graphql_name, actual_type.graphql_name
        assert_equal_or_nil expected_type.description, actual_type.description
        assert_deep_equal expected_type.values.values.sort_by(&:graphql_name), actual_type.values.values.sort_by(&:graphql_name)
      elsif actual_type < GraphQL::Schema::InputObject
        assert_equal_or_nil expected_type.graphql_name, actual_type.graphql_name
        assert_equal_or_nil expected_type.arguments.keys.sort, actual_type.arguments.keys.sort
        assert_deep_equal expected_type.arguments.values.sort_by(&:graphql_name), actual_type.arguments.values.sort_by(&:graphql_name)
      elsif actual_type < GraphQL::Schema::Directive
        assert_equal_or_nil expected_type.graphql_name, actual_type.graphql_name
        assert_equal_or_nil expected_type.description, actual_type.description
        assert_equal_or_nil expected_type.repeatable?, actual_type.repeatable?
        assert_equal_or_nil expected_type.locations.sort, actual_type.locations.sort
        assert_equal_or_nil expected_type.arguments.keys.sort, actual_type.arguments.keys.sort
        assert_deep_equal expected_type.arguments.values.sort_by(&:graphql_name), actual_type.arguments.values.sort_by(&:graphql_name)
      else
        assert_equa_or_nil expected_type, actual_type
      end
    end

    let(:loaded_schema) { GraphQL::Schema.from_introspection(schema_json) }

    it "returns the schema without warnings" do
      assert_warns("") do
        assert_deep_equal(schema, loaded_schema)
      end
    end

    it "can export the loaded schema" do
      assert loaded_schema.execute(GraphQL::Introspection::INTROSPECTION_QUERY)
    end

    it "has no-op coerce functions" do
      custom_scalar = loaded_schema.types["BigInt"]
      assert_equal true, custom_scalar.valid_isolated_input?("anything")
      assert_equal true, custom_scalar.valid_isolated_input?(12345)
    end

    it "sets correct default values on custom scalar arguments" do
      type = loaded_schema.types["Comment"]
      field = type.fields['fieldWithArg']
      arg = field.arguments['bigint']

      assert_equal((2**54).to_s, arg.default_value)
    end

    it "sets correct default values on custom scalar input fields" do
      type = loaded_schema.types["Varied"]
      field = type.arguments['bigint']

      assert_equal((2**54).to_s, field.default_value)
    end

    it "sets correct default values for complex field arguments" do
      type = loaded_schema.types['Query']
      field = type.fields['post']

      varied = field.arguments['varied']
      assert_equal varied.default_value, { 'id' => "123", 'int' => 234, 'float' => 2.3, 'enum' => "FOO", 'sub' => [{ 'string' => "str" }] }
      assert !varied.default_value.key?('bool'), 'Omits default value for unspecified arguments'

      variedArray = field.arguments['variedArray']
      assert_equal variedArray.default_value, [{ 'id' => "123", 'int' => 234, 'float' => 2.3, 'enum' => "FOO", 'sub' => [{ 'string' => "str" }] }]
      assert !variedArray.default_value.first.key?('bool'), 'Omits default value for unspecified arguments'

      array = field.arguments['array']
      assert_equal array.default_value, ["foo", "bar"]
    end

    it "does not set default value when there are none on input fields" do
      type = loaded_schema.types['Varied']

      assert !type.arguments['id'].default_value?
      assert !type.arguments['int'].default_value?
      assert type.arguments['bigint'].default_value?
      assert !type.arguments['float'].default_value?
      assert !type.arguments['bool'].default_value?
      assert !type.arguments['enum'].default_value?
      assert !type.arguments['sub'].default_value?
    end

    it "sets correct default values `null` on input fields" do
      type = loaded_schema.types['VariedWithNulls']

      assert type.arguments['id'].default_value?
      assert type.arguments['id'].default_value.nil?

      assert type.arguments['int'].default_value?
      assert type.arguments['int'].default_value.nil?

      assert type.arguments['bigint'].default_value?
      assert type.arguments['bigint'].default_value.nil?

      assert type.arguments['float'].default_value?
      assert type.arguments['float'].default_value.nil?

      assert type.arguments['bool'].default_value?
      assert type.arguments['bool'].default_value.nil?

      assert type.arguments['enum'].default_value?
      assert type.arguments['enum'].default_value.nil?

      assert type.arguments['sub'].default_value?
      assert type.arguments['sub'].default_value.nil?
    end

    it "works with underscored names" do
      schema_sdl = <<-GRAPHQL
type A_Type {
  f(argument_1: Int, argument_two: Int): Int
}

type Query {
  some_field: A_Type
}
      GRAPHQL

      introspection_res = GraphQL::Schema.from_definition(schema_sdl).as_json
      rebuilt_schema = GraphQL::Schema.from_introspection(introspection_res)

      assert_equal schema_sdl, rebuilt_schema.to_definition
    end

    it "doesnt warn about method conflicts (because it doesn't make method accesses)" do
      assert_output "", "" do
        GraphQL::Schema.from_introspection({
          "data" => {
            "__schema" => {
              "queryType" => {
                "name" => "Query"
              },
              "mutationType" => nil,
              "subscriptionType" => nil,
              "types" => [
                {
                  "kind" => "OBJECT",
                  "name" => "Query",
                  "description" => nil,
                  "fields" => [
                    {
                      "name" => "int",
                      "description" => nil,
                      "args" => [
                        {
                          "name" => "method",
                          "description" => nil,
                          "type" => {
                            "kind" => "SCALAR",
                            "name" => "Int",
                            "ofType" => nil
                          },
                          "defaultValue" => nil
                        }
                      ],
                      "type" => {
                        "kind" => "SCALAR",
                        "name" => "Int",
                        "ofType" => nil
                      },
                      "isDeprecated" => false,
                      "deprecationReason" => nil
                    }
                  ],
                  "inputFields" => nil,
                  "interfaces" => [

                  ],
                  "enumValues" => nil,
                  "possibleTypes" => nil
                },
                {
                  "kind" => "SCALAR",
                  "name" => "Int",
                  "description" => "Represents non-fractional signed whole numeric values. Int can represent values between -(2^31) and 2^31 - 1.",
                  "fields" => nil,
                  "inputFields" => nil,
                  "interfaces" => nil,
                  "enumValues" => nil,
                  "possibleTypes" => nil
                },
              ]
            }
          }
        })
      end
    end

    it "sets correct default values `nil` on complex field arguments" do
      type = loaded_schema.types['Query']
      field = type.fields['post']
      arg = field.arguments['variedWithNull']

      assert_equal arg.default_value, { 'id' => nil, 'int' => nil, 'float' => nil, 'enum' => nil, 'sub' => nil, 'bool' => nil, 'bigint' => nil }
    end
  end

  it "validates field argument names" do
    json = {
      "data" => {
        "__schema" => {
          "queryType" => {
            "name" => "Query"
          },
          "mutationType" => nil,
          "subscriptionType" => nil,
          "types" => [
            {
              "kind" => "OBJECT",
              "name" => "Query",
              "description" => nil,
              "fields" => [
                {
                  "name" => "int",
                  "description" => nil,
                  "type" => {
                    "kind" => "SCALAR",
                    "name" => "Int",
                    "ofType" => nil,
                  },
                  "args" => [
                    {
                      "name" => "something-wrong",
                      "description" => nil,
                      "type" => {
                        "kind" => "SCALAR",
                        "name" => "Int",
                        "ofType" => nil
                      },
                      "defaultValue" => nil
                    }
                  ],
                }
              ]
            }
          ]
        }
      }
    }
    err = assert_raises GraphQL::InvalidNameError do
      GraphQL::Schema.from_introspection(json)
    end

    assert_includes err.message, "something-wrong"
  end

  it "validates field names" do
    json = {
      "data" => {
        "__schema" => {
          "queryType" => {
            "name" => "Query"
          },
          "mutationType" => nil,
          "subscriptionType" => nil,
          "types" => [
            {
              "kind" => "OBJECT",
              "name" => "Query",
              "description" => nil,
              "fields" => [
                {
                  "name" => "bad.int",
                  "description" => nil,
                  "type" => {
                    "kind" => "SCALAR",
                    "name" => "Int",
                    "ofType" => nil,
                  },
                  "args" => [],
                }
              ]
            }
          ]
        }
      }
    }
    err = assert_raises GraphQL::InvalidNameError do
      GraphQL::Schema.from_introspection(json)
    end

    assert_includes err.message, "bad.int"
  end

  it "validates input object argument names" do
    json = {
      "data" => {
        "__schema" => {
          "queryType" => {
            "name" => "Query"
          },
          "mutationType" => nil,
          "subscriptionType" => nil,
          "types" => [
            {
              "kind" => "OBJECT",
              "name" => "Query",
              "description" => nil,
              "fields" => [
                {
                  "name" => "int",
                  "description" => nil,
                  "type" => {
                    "kind" => "SCALAR",
                    "name" => "Int",
                    "ofType" => nil,
                  },
                  "args" => [
                    {
                      "name" => "inputObject",
                      "description" => nil,
                      "type" => {
                        "kind" => "INPUT_OBJECT",
                        "name" => "SomeInputObject",
                        "ofType" => nil
                      },
                      "defaultValue" => nil
                    }
                  ],
                }
              ]
            },
            {
              "kind" => "INPUT_OBJECT",
              "name" => "SomeInputObject",
              "description" => nil,
              "inputFields" => [
                {
                  "name"=>"bad, input",
                  "type"=> { "kind" => "SCALAR", "name" => "String"},
                  "defaultValue"=> nil,
                  "description" => nil,
                },
              ]
            }
          ]
        }
      }
    }
    err = assert_raises GraphQL::InvalidNameError do
      GraphQL::Schema.from_introspection(json)
    end

    assert_includes err.message, "bad, input"
  end
end
