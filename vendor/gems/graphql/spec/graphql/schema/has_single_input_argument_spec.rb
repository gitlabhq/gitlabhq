# frozen_string_literal: true
require 'spec_helper'

describe GraphQL::Schema::HasSingleInputArgument do
  describe ".input_object_class" do
    it "is inherited, with a default" do
      custom_input = Class.new(GraphQL::Schema::InputObject)
      mutation_base_class = Class.new(GraphQL::Schema::Mutation) do
        include GraphQL::Schema::HasSingleInputArgument
        graphql_name "Test"
        input_object_class(custom_input)
      end
      mutation_subclass = Class.new(mutation_base_class)

      assert_equal custom_input, mutation_base_class.input_object_class
      assert_equal custom_input, mutation_subclass.input_object_class
    end
  end

  describe ".input_type" do
    it "has a reference to the mutation" do
      mutation = Class.new(GraphQL::Schema::Mutation) do
        include GraphQL::Schema::HasSingleInputArgument
        graphql_name "Test"
      end
      assert_equal mutation, mutation.input_type.mutation
    end
  end

  describe "input argument" do
    it "sets a description for the input argument" do
      mutation = Class.new(GraphQL::Schema::Mutation) do
        include GraphQL::Schema::HasSingleInputArgument
        graphql_name "SomeMutation"
      end

      field = GraphQL::Schema::Field.new(name: "blah", resolver_class: mutation)
      assert_equal "Parameters for SomeMutation", field.get_argument("input").description
    end
  end

  describe "execution" do
    module HasSingleArgument
      class TestInput < GraphQL::Schema::InputObject
        argument :name, String
      end

      class NoArgumentMutation < GraphQL::Schema::Mutation
        include GraphQL::Schema::HasSingleInputArgument

        null true

        field :name, String, null: false
        def resolve
          { name: "name" }
        end
      end

      class InputObjectMutation < GraphQL::Schema::Mutation
        include GraphQL::Schema::HasSingleInputArgument

        argument :test, TestInput

        field :name, String

        def resolve(test:)
          { name: test[:name] }
        end
      end

      class SupportExtrasMutation < GraphQL::Schema::Mutation
        include GraphQL::Schema::HasSingleInputArgument

        argument :name, String
        extras [:ast_node]

        field :node_class, String
        field :name, String

        def resolve(name:, ast_node:)
          {
            name: name,
            node_class: ast_node.class.name
          }
        end
      end

      class SupportFieldExtrasMutation < GraphQL::Schema::Mutation
        include GraphQL::Schema::HasSingleInputArgument

        null true

        argument :name, String, required: false

        field :lookahead_class, String, null: false
        field :name, String

        def resolve(name: nil, lookahead:)
          {
            name: name,
            lookahead_class: lookahead.class.name
          }
        end
      end

      class CanStripOutExtrasMutation < GraphQL::Schema::Mutation
        include GraphQL::Schema::HasSingleInputArgument

        extras [:lookahead]

        field :name, String, null: false

        def resolve_with_support(lookahead: , **rest)
          context[:has_lookahead] = !!lookahead
          super(**rest)
        end

        def authorized?
          true
        end

        def resolve
          {
            name: 'name',
          }
        end
      end
      class Mutation < GraphQL::Schema::Object
        field_class GraphQL::Schema::Field

        field :no_argument, mutation: NoArgumentMutation
        field :input_object, mutation: InputObjectMutation
        field :support_extras, mutation: SupportExtrasMutation
        field :support_field_extras, mutation: SupportFieldExtrasMutation, extras: [:lookahead]
        field :can_strip_out_extras, mutation: CanStripOutExtrasMutation
      end
      class Schema < GraphQL::Schema
        mutation(Mutation)
      end
    end

    it "works with no arguments" do
      res = HasSingleArgument::Schema.execute <<-GRAPHQL
      mutation {
        noArgument(input: {}) {
          name
        }
      }
      GRAPHQL
      assert_equal "name", res["data"]["noArgument"]["name"]
    end

    it "works with InputObject arguments" do
      res = HasSingleArgument::Schema.execute <<-GRAPHQL
      mutation {
        inputObject(input: { test: { name: "test name" } }) {
          name
        }
      }
      GRAPHQL

      assert_equal "test name", res["data"]["inputObject"]["name"]
    end

    it "supports extras" do
      res = HasSingleArgument::Schema.execute <<-GRAPHQL
      mutation {
        supportExtras(input: {name: "name"}) {
          nodeClass
          name
        }
      }
      GRAPHQL

      assert_equal "GraphQL::Language::Nodes::Field", res["data"]["supportExtras"]["nodeClass"]
      assert_equal "name", res["data"]["supportExtras"]["name"]

      # Also test with given args
      res = Jazz::Schema.execute <<-GRAPHQL
      mutation {
        hasExtras(input: {int: 5}) {
          nodeClass
          int
        }
      }
      GRAPHQL
      assert_equal "GraphQL::Language::Nodes::Field", res["data"]["hasExtras"]["nodeClass"]
      assert_equal 5, res["data"]["hasExtras"]["int"]
    end

    it "supports field extras" do
      res = HasSingleArgument::Schema.execute <<-GRAPHQL
      mutation {
        supportFieldExtras(input: {}) {
          lookaheadClass
          name
        }
      }
      GRAPHQL

      assert_equal "GraphQL::Execution::Lookahead", res["data"]["supportFieldExtras"]["lookaheadClass"]
      assert_nil res["data"]["supportFieldExtras"]["name"]

      # Also test with given args
      res = HasSingleArgument::Schema.execute <<-GRAPHQL
      mutation {
        supportFieldExtras(input: {name: "name"}) {
          lookaheadClass
          name
        }
      }
      GRAPHQL
      assert_equal "GraphQL::Execution::Lookahead", res["data"]["supportFieldExtras"]["lookaheadClass"]
      assert_equal "name", res["data"]["supportFieldExtras"]["name"]
    end

    it "can strip out extras" do
      ctx = {}
      res = HasSingleArgument::Schema.execute <<-GRAPHQL, context: ctx
      mutation {
        canStripOutExtras(input: {}) {
          name
        }
      }
      GRAPHQL
      assert_equal true, ctx[:has_lookahead]
      assert_equal "name", res["data"]["canStripOutExtras"]["name"]
    end
  end
end
