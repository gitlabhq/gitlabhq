# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Query::Variables do
  let(:query_string) {%|
  query getCheese(
    $animals: [DairyAnimal!],
    $intDefaultNull: Int = null,
    $int: Int,
    $intWithDefault: Int = 10)
  {
    cheese(id: 1) {
      similarCheese(source: $animals)
    }
  }
  |}
  let(:ast_variables) { GraphQL.parse(query_string).definitions.first.variables }
  let(:schema) { Dummy::Schema }
  let(:query_context) { GraphQL::Query.new(schema, "{ __typename }").context }
  let(:variables) {
    GraphQL::Query::Variables.new(
    query_context,
    ast_variables,
    provided_variables)
  }

  describe "#to_h" do
    let(:provided_variables) { { "animals" => "YAK" } }

    it "returns a hash representation including default values" do
      expected_hash = {
        "animals" => "YAK", # This is converted to a single-item list later on
        "intDefaultNull" => nil,
        "intWithDefault" => 10,
      }
      assert_equal expected_hash, variables.to_h
    end
  end

  describe "#initialize" do
    describe "validating input objects" do
      let(:query_string) {%|
      query searchMyDairy (
        $product: DairyProductInput
      ) {
        searchDairy(product: $product) {
          ... on Cheese {
            flavor
          }
        }
      }
      |}

      describe "when provided input is an array" do
        let(:provided_variables) { { "product" => [] } }

        it "validates invalid input objects" do
          expected = "Variable $product of type DairyProductInput was provided invalid value"
          assert_equal expected, variables.errors.first.message
        end
      end

      describe "when provided input cannot be coerced" do
        let(:query_string) {%|
        query searchMyDairy (
          $time: Time
        ) {
          searchDairy(expiresAfter: $time) {
            ... on Cheese {
              flavor
            }
          }
        }
        |}
        let(:provided_variables) { { "time" => "a" } }

        it "validates invalid input objects" do
          expected = "Variable $time of type Time was provided invalid value"
          assert_equal expected, variables.errors.first.message
        end
      end
    end

    describe "nullable variables" do
      module ObjectWithThingsCount
        def self.thingsCount(args, ctx) # rubocop:disable Naming/MethodName
          1
        end
      end

      let(:schema) { GraphQL::Schema.from_definition(%|
        type Query {
          thingsCount(ids: [ID!]): Int!
        }
      |)
      }
      let(:query_string) {%|
        query getThingsCount($ids: [ID!]) {
          thingsCount(ids: $ids)
        }
      |}
      let(:result) {
        schema.execute(query_string, variables: provided_variables, root_value: ObjectWithThingsCount)
      }

      describe "when they are present, but null" do
        let(:provided_variables) { { "ids" => nil } }
        it "ignores them" do
          assert_equal 1, result["data"]["thingsCount"]
        end
      end

      describe "when they are not present" do
        let(:provided_variables) { {} }
        it "ignores them" do
          assert_equal 1, result["data"]["thingsCount"]
        end
      end

      describe "when a non-nullable list has a null in it" do
        let(:provided_variables) { { "ids" => [nil] } }
        it "returns an error" do
          assert_equal 1, result["errors"].length
          assert_nil result["data"]
        end
      end
    end

    describe "coercing null" do
      let(:provided_variables) {
        {
          "intWithVariable" => nil,
          "intWithDefault" => nil,
          "complexValWithVariable" => {
            "val" => 1,
            "val_with_default" => 2,
          },
          "complexValWithDefaultAndVariable" => {
            "val" => 8,
          },
        }
      }
      let(:args) { {} }
      let(:schema) {
        args_cache = args

        complex_val = Class.new(GraphQL::Schema::InputObject) do
          graphql_name "ComplexVal"
          argument :val, Integer, required: false, camelize: false
          argument :val_with_default, Integer, required: false, default_value: 13, camelize: false
        end

        query_type = Class.new(GraphQL::Schema::Object) do
          graphql_name "Query"
          field :variables_test, Integer, extras: [:ast_node], camelize: false do
            argument :val, Integer, required: false
            argument :val_with_default, Integer, required: false, default_value: 13, camelize: false
            argument :complex_val, complex_val, required: false, camelize: false
          end

          def variables_test(ast_node:, **args)
            context.schema.args_cache[ast_node.alias] = args
            1
          end
        end

        Class.new(GraphQL::Schema) do
          query(query_type)

          class << self
            attr_accessor :args_cache
          end

          self.args_cache = args_cache
        end
      }

      let(:query_string) {<<-GRAPHQL
        query testVariables(
          $intWithVariable: Int,
          $intWithDefault: Int = 10,
          $intDefaultNull: Int = null,
          $intWithoutVariable: Int,
          $complexValWithVariable: ComplexVal,
          $complexValWithoutVariable: ComplexVal,
          $complexValWithOneDefault: ComplexVal = { val: 10 },
          $complexValWithTwoDefaults: ComplexVal = { val: 11, val_with_default: 11 },
          $complexValWithNullDefaults: ComplexVal = { val: null, val_with_default: null },
          $complexValWithDefaultAndVariable: ComplexVal = { val: 99 },
        ) {
          aa: variables_test(val: $intWithVariable)
          ab: variables_test(val: $intWithoutVariable)
          ac: variables_test(val: $intWithDefault)
          ad: variables_test(val: $intDefaultNull)

          ba: variables_test(val_with_default: $intWithVariable)
          bb: variables_test(val_with_default: $intWithoutVariable)
          bc: variables_test(val_with_default: $intWithDefault)
          bd: variables_test(val_with_default: $intDefaultNull)

          ca: variables_test(complex_val: { val: $intWithVariable })
          cb: variables_test(complex_val: { val: $intWithoutVariable })
          cc: variables_test(complex_val: { val: $intWithDefault })
          cd: variables_test(complex_val: { val: $intDefaultNull })

          da: variables_test(complex_val: { val_with_default: $intWithVariable })
          db: variables_test(complex_val: { val_with_default: $intWithoutVariable })
          dc: variables_test(complex_val: { val_with_default: $intWithDefault })
          dd: variables_test(complex_val: { val_with_default: $intDefaultNull })

          ea: variables_test(complex_val: $complexValWithVariable)
          eb: variables_test(complex_val: $complexValWithoutVariable)
          ec: variables_test(complex_val: $complexValWithOneDefault)
          ed: variables_test(complex_val: $complexValWithTwoDefaults)
          ee: variables_test(complex_val: $complexValWithNullDefaults)
          ef: variables_test(complex_val: $complexValWithDefaultAndVariable)
        }
      GRAPHQL
      }

      let(:run_query) {
        schema.execute(query_string, variables: provided_variables)
      }

      let(:variables) { GraphQL::Query::Variables.new(
        query_context,
        ast_variables,
        provided_variables)
      }

      def assert_has_key_with_value(hash, key, has_key, value)
        assert_equal(has_key, hash.key?(key))
        if value.nil?
          assert_nil hash[key]
        else
          assert_equal(value, hash[key])
        end
      end

      it "preserves explicit null" do
        assert_has_key_with_value(variables, "intWithVariable", true, nil)
        run_query
        # Provided `nil` should be passed along to args
        # and override any defaults (variable defaults and arg defaults)
        assert_has_key_with_value(args["aa"], :val, true, nil)
        assert_has_key_with_value(args["ba"], :val_with_default, true, nil)
        assert_has_key_with_value(args["ca"][:complex_val], :val, true, nil)
        assert_has_key_with_value(args["da"][:complex_val], :val_with_default, true, nil)
      end

      it "doesn't contain variables that weren't present" do
        assert_has_key_with_value(variables, "intWithoutVariable", false, nil)
        run_query
        assert_has_key_with_value(args["ab"], :val, false, nil)
        # This one _is_ present, it gets the argument.default_value
        assert_has_key_with_value(args["bb"], :val_with_default, true, 13)
        assert_has_key_with_value(args["cb"][:complex_val], :val, false, nil)
        # This one _is_ present, it gets the argument.default_value
        assert_has_key_with_value(args["db"][:complex_val], :val_with_default, true, 13)
      end

      it "preserves explicit null when variable has a default value" do
        assert_has_key_with_value(variables, "intWithDefault", true, nil)
        run_query
        assert_has_key_with_value(args["ac"], :val, true, nil)
        assert_has_key_with_value(args["bc"], :val_with_default, true, nil)
        assert_has_key_with_value(args["cc"][:complex_val], :val, true, nil)
        assert_has_key_with_value(args["dc"][:complex_val], :val_with_default, true, nil)
      end

      it "uses null default value" do
        assert_has_key_with_value(variables, "intDefaultNull", true, nil)
        run_query
        assert_has_key_with_value(args["ad"], :val, true, nil)
        assert_has_key_with_value(args["bd"], :val_with_default, true, nil)
        assert_has_key_with_value(args["cd"][:complex_val], :val, true, nil)
        assert_has_key_with_value(args["dd"][:complex_val], :val_with_default, true, nil)
      end

      it "applies argument default values" do
        run_query
        # It wasn't present in the query string, but it gets argument.default_value:
        assert_has_key_with_value(args["aa"], :val_with_default, true, 13)
      end

      it "applies coercion to input objects passed as variables" do
        run_query
        assert_has_key_with_value(args["ea"][:complex_val], :val, true, 1)
        assert_has_key_with_value(args["ea"][:complex_val], :val_with_default, true, 2)

        # Since the variable wasn't provided, it's not present at all:
        assert_has_key_with_value(args["eb"], :complex_val, false, nil)

        assert_has_key_with_value(args["ec"][:complex_val], :val, true, 10)
        assert_has_key_with_value(args["ec"][:complex_val], :val_with_default, true, 13)

        assert_has_key_with_value(args["ed"][:complex_val], :val, true, 11)
        assert_has_key_with_value(args["ed"][:complex_val], :val_with_default, true, 11)

        assert_has_key_with_value(args["ee"][:complex_val], :val, true, nil)
        assert_has_key_with_value(args["ee"][:complex_val], :val_with_default, true, nil)

        assert_has_key_with_value(args["ef"][:complex_val], :val, true, 8)
        assert_has_key_with_value(args["ef"][:complex_val], :val_with_default, true, 13)
      end
    end
  end

  if ActionPack::VERSION::MAJOR > 3
    describe "with a ActionController::Parameters" do
      let(:query_string) { <<-GRAPHQL
        query getCheeses($source: DairyAnimal!, $fatContent: Float!){
          searchDairy(product: [{source: $source, fatContent: $fatContent}]) {
            ... on Cheese { flavor }
          }
        }
      GRAPHQL
      }
      let(:params) do
        ActionController::Parameters.new(
          "variables" => {
            "source" => "COW",
            "fatContent" => 0.4,
          }
        )
      end

      it "works" do
        res = schema.execute(query_string, variables: params["variables"])
        assert_equal 1, res["data"]["searchDairy"].length
      end
    end
  end
end
