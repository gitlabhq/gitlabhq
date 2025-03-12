# frozen_string_literal: true
require "spec_helper"
require "uri"
describe GraphQL::StaticValidation::ArgumentLiteralsAreCompatible do
  include StaticValidationHelpers

  let(:query_string) {%|
    query getCheese {
      stringCheese: cheese(id: "aasdlkfj") { ...cheeseFields }
      cheese(id: 1) { source @skip(if: "whatever") }
      yakSource: searchDairy(product: [{source: COW, fatContent: 1.1}]) { __typename }
      badSource: searchDairy(product: {source: 1.1}) { __typename }
      missingSource: searchDairy(product: [{fatContent: 1.1}]) { __typename }
      listCoerce: cheese(id: 1) { similarCheese(source: YAK) { __typename } }
      missingInputField: searchDairy(product: [{source: YAK, wacky: 1}]) { __typename }
    }

    fragment cheeseFields on Cheese {
      similarCheese(source: 4.5) { __typename }
    }
  |}

  it "finds undefined or missing-required arguments to fields and directives" do
    # `wacky` above is handled by ArgumentsAreDefined, missingSource is handled by RequiredInputObjectAttributesArePresent
    # so only 4 are tested below
    assert_equal(6, errors.length)

    query_root_error = {
      "message"=>"Argument 'id' on Field 'stringCheese' has an invalid value (\"aasdlkfj\"). Expected type 'Int!'.",
      "locations"=>[{"line"=>3, "column"=>7}],
      "path"=>["query getCheese", "stringCheese", "id"],
      "extensions"=>{"code"=>"argumentLiteralsIncompatible", "typeName"=>"Field", "argumentName"=>"id"},
    }
    assert_includes(errors, query_root_error)

    directive_error = {
      "message"=>"Argument 'if' on Directive 'skip' has an invalid value (\"whatever\"). Expected type 'Boolean!'.",
      "locations"=>[{"line"=>4, "column"=>30}],
      "path"=>["query getCheese", "cheese", "source", "if"],
      "extensions"=>{"code"=>"argumentLiteralsIncompatible", "typeName"=>"Directive", "argumentName"=>"if"},
    }
    assert_includes(errors, directive_error)

    input_object_field_error = {
      "message"=>"Argument 'source' on InputObject 'DairyProductInput' has an invalid value (1.1). Expected type 'DairyAnimal!'.",
      "locations"=>[{"line"=>6, "column"=>39}],
      "path"=>["query getCheese", "badSource", "product", 0, "source"],
      "extensions"=>{"code"=>"argumentLiteralsIncompatible", "typeName"=>"InputObject", "argumentName"=>"source"},
    }
    assert_includes(errors, input_object_field_error)

    fragment_error = {
      "message"=>"Argument 'source' on Field 'similarCheese' has an invalid value (4.5). Expected type '[DairyAnimal!]!'.",
      "locations"=>[{"line"=>13, "column"=>7}],
      "path"=>["fragment cheeseFields", "similarCheese", "source"],
      "extensions"=> {"code"=>"argumentLiteralsIncompatible", "typeName"=>"Field", "argumentName"=>"source"}
    }
    assert_includes(errors, fragment_error)
  end

  describe "using input objects for enums it adds an error" do
    let(:query_string) { <<-GRAPHQL
      {
        yakSource: searchDairy(product: [{source: {a: 1, b: 2}, fatContent: 1.1}]) { __typename }
      }
    GRAPHQL
    }
    it "works" do
      assert_equal 1, errors.length
    end
  end

  describe "using enums for scalar arguments it adds an error" do
    let(:query_string) { <<-GRAPHQL
      {
        cheese(id: I_AM_ENUM_VALUE) {
          source
        }
      }
    GRAPHQL
    }

    let(:enum_invalid_for_id_error) do
      {
        "message" => "Argument 'id' on Field 'cheese' has an invalid value (I_AM_ENUM_VALUE). Expected type 'Int!'.",
        "locations" => [{ "line" => 2, "column" => 9 }],
        "path"=> ["query", "cheese", "id"],
        "extensions"=> { "code" => "argumentLiteralsIncompatible", "typeName" => "Field", "argumentName" => "id" }
      }
    end

    it "works" do
      assert_includes(errors, enum_invalid_for_id_error)
      assert_equal 1, errors.length
    end
  end

  describe "null value" do
    describe "nullable arg" do
      let(:schema) {
        GraphQL::Schema.from_definition(%|
          type Query {
            field(arg: Int): Int
          }
        |)
      }
      let(:query_string) {%|
        query {
          field(arg: null)
        }
      |}

      it "finds no errors" do
        assert_equal [], errors
      end
    end

    describe "non-nullable arg" do
      let(:schema) {
        GraphQL::Schema.from_definition(%|
          type Query {
            field(arg: Int!): Int
          }
        |)
      }
      let(:query_string) {%|
        query {
          field(arg: null)
        }
      |}

      it "finds error" do
        assert_equal [{
          "message"=>"Argument 'arg' on Field 'field' has an invalid value (null). Expected type 'Int!'.",
          "locations"=>[{"line"=>3, "column"=>11}],
          "path"=>["query", "field", "arg"],
          "extensions"=>{"code"=>"argumentLiteralsIncompatible", "typeName"=>"Field", "argumentName"=>"arg"}
        }], errors
      end
    end

    describe "non-nullable array" do
      let(:schema) {
        GraphQL::Schema.from_definition(%|
          type Query {
            field(arg: [Int!]): Int
          }
        |)
      }
      let(:query_string) {%|
        query {
          field(arg: [null])
        }
      |}

      it "finds error" do
        assert_equal [{
          "message"=>"Argument 'arg' on Field 'field' has an invalid value ([null]). Expected type '[Int!]'.",
          "locations"=>[{"line"=>3, "column"=>11}],
          "path"=>["query", "field", "arg"],
          "extensions"=>{"code"=>"argumentLiteralsIncompatible", "typeName"=>"Field", "argumentName"=>"arg"}
        }], errors
      end
    end

    describe "array with nullable values" do
      let(:schema) {
        GraphQL::Schema.from_definition(%|
          type Query {
            field(arg: [Int]): Int
          }
        |)
      }
      let(:query_string) {%|
        query {
          field(arg: [null])
        }
      |}

      it "finds no errors" do
        assert_equal [], errors
      end
    end

    describe "input object" do
      let(:schema) {
        GraphQL::Schema.from_definition(%|
          type Query {
            field(arg: Input): Int
          }

          input Input {
            a: Int
            b: Int!
          }
        |)
      }
      let(:query_string) {%|
        query {
          field(arg: {a: null, b: null})
        }
      |}

      it "it finds errors" do
        assert_equal 1, errors.length
        refute_includes errors, {
          "message"=>"Argument 'arg' on Field 'field' has an invalid value ({a: null, b: null}). Expected type 'Input'.",
          "locations"=>[{"line"=>3, "column"=>11}],
          "path"=>["query", "field", "arg"],
          "extensions"=>{"code"=>"argumentLiteralsIncompatible", "typeName"=>"Field", "argumentName"=>"arg"}
        }
        assert_includes errors, {
          "message"=>"Argument 'b' on InputObject 'Input' has an invalid value (null). Expected type 'Int!'.",
          "locations"=>[{"line"=>3, "column"=>22}],
          "path"=>["query", "field", "arg", "b"],
          "extensions"=>{"code"=>"argumentLiteralsIncompatible", "typeName"=>"InputObject", "argumentName"=>"b"}
        }
      end
    end
  end

  describe "dynamic fields" do
    let(:query_string) {"
      query {
        __type(name: 1) { name }
      }
    "}

    it "finds invalid argument types" do
      assert_includes(errors, {
        "message"=>"Argument 'name' on Field '__type' has an invalid value (1). Expected type 'String!'.",
        "locations"=>[{"line"=>3, "column"=>9}],
        "path"=>["query", "__type", "name"],
        "extensions"=>{"code"=>"argumentLiteralsIncompatible", "typeName"=>"Field", "argumentName"=>"name"}
      })
    end
  end

  describe "error references argument" do
    let(:validator) { GraphQL::StaticValidation::Validator.new(schema: schema) }
    let(:query) { GraphQL::Query.new(schema, query_string) }
    let(:errors) { validator.validate(query)[:errors] }
    let(:query_string) {"
      query {
        cheese(id: true) { source }
        milk(id: 1) { source @skip(if: TRUE) }
      }
    "}

    it "works with field" do
      id_argument = schema.types['Query'].fields['cheese'].get_argument('id')
      error = errors.find { |error| error.argument_name == 'id' }

      assert_equal id_argument, error.argument
      assert_equal true, error.value
    end

    it "works with directive" do
      if_argument = schema.directives['skip'].get_argument('if')
      error = errors.find { |error| error.argument_name == 'if' }

      assert_equal if_argument, error.argument
      assert_instance_of GraphQL::Language::Nodes::Enum, error.value
      assert_equal "TRUE", error.value.name
    end
  end

  class CustomErrorMessagesSchema < GraphQL::Schema
    class TimeType < GraphQL::Schema::Scalar
      description "Time since epoch in seconds"

      def self.coerce_input(value, ctx)
        Time.at(Float(value))
      rescue ArgumentError
        raise GraphQL::CoercionError, 'cannot coerce to Float'
      end

      def self.coerce_result(value, ctx)
        value.to_f
      end
    end

    class RangeType < GraphQL::Schema::InputObject
      argument :from, TimeType
      argument :to, TimeType
    end

    class EmailType < GraphQL::Schema::Scalar

      def self.coerce_input(value, ctx)
        if URI::MailTo::EMAIL_REGEXP.match(value)
          value
        else
          raise GraphQL::CoercionError.new("Invalid email address", extensions: { "code" => "invalid_email_address" })
        end
      end

      def self.coerce_result(value, ctx)
        value.to_f
      end
    end

    class Query < GraphQL::Schema::Object
      description "The query root of this schema"

      field :time, TimeType do
        argument :value, TimeType, required: false
        argument :range, RangeType, required: false
      end

      def time(value: nil, range: nil)
        value
      end

      field :email, EmailType do
        argument :value, EmailType, required: false
      end

      def email(value:)
        value
      end
    end

    query(Query)
  end

  describe "custom error messages" do
    let(:schema) { CustomErrorMessagesSchema }

    let(:query_string) {%|
      query {
        time(value: "a")
      }
    |}

    describe "with a shallow coercion" do
      it "sets error message from a CoercionError if raised" do
        assert_equal 1, errors.length

        assert_includes errors, {
          "message"=> "cannot coerce to Float",
          "locations"=>[{"line"=>3, "column"=>9}],
          "path"=>["query", "time", "value"],
          "extensions"=>{"code"=>"argumentLiteralsIncompatible", "typeName"=>"CoercionError"}
        }
      end
    end

    describe "with a deep coercion" do
      let(:query_string) {%|
        query {
          time(range: { from: "a", to: "b" })
        }
      |}

      from_error = {
        "message"=>"cannot coerce to Float",
        "locations"=>[{"line"=>3, "column"=>23}],
        "path"=>["query", "time", "range", "from"],
        "extensions"=>{"code"=>"argumentLiteralsIncompatible", "typeName"=>"CoercionError"},
      }

      to_error = {
        "message"=>"cannot coerce to Float",
        "locations"=>[{"line"=>3, "column"=>23}],
        "path"=>["query", "time", "range", "to"],
        "extensions"=>{"code"=>"argumentLiteralsIncompatible", "typeName"=>"CoercionError"},
      }

      bubbling_error = {
        "message"=>"cannot coerce to Float",
        "locations"=>[{"line"=>3, "column"=>11}],
        "path"=>["query", "time", "range"],
        "extensions"=>{"code"=>"argumentLiteralsIncompatible", "typeName"=>"CoercionError"},
      }

      describe "sets deep error message from a CoercionError if raised" do
        it "works" do
          assert_equal 2, errors.length
          assert_includes(errors, from_error)
          assert_includes(errors, to_error)
          refute_includes(errors, bubbling_error)
        end
      end
    end
  end

  describe "custom error extensions" do
    let(:schema) { CustomErrorMessagesSchema }

    let(:query_string) {%|
      query {
        email(value: "a")
      }
    |}

    describe "with a shallow coercion" do
      it "sets error extensions code from a CoercionError if raised" do
        assert_equal 1, errors.length

        assert_includes errors, {
          "message"=> "Invalid email address",
          "locations"=>[{"line"=>3, "column"=>9}],
          "path"=>["query", "email", "value"],
          "extensions"=>{"code"=>"invalid_email_address", "typeName"=>"CoercionError"}
        }
      end
    end
  end
end
