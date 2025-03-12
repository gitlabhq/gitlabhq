# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Current do
  describe "when no query is running" do
    it "returns nil for things" do
      assert_nil GraphQL::Current.operation_name
      assert_nil GraphQL::Current.field
      assert_nil GraphQL::Current.dataloader_source_class
    end
  end

  describe "in queries" do
    class CurrentSchema < GraphQL::Schema
      class ThingSource < GraphQL::Dataloader::Source
        def initialize(context)
          @context = context
        end

        def fetch(names)
          @context[:current_operation_name] << GraphQL::Current.operation_name
          @context[:current_source] << GraphQL::Current.dataloader_source_class
          names
        end
      end
      class Thing < GraphQL::Schema::Object
        field :name, String

        def name
          context[:current_field] << GraphQL::Current.field.path
          context.dataloader.with(ThingSource, context).load("thing")
        end
      end
      class Query < GraphQL::Schema::Object
        field :thing, Thing

        def thing
          context[:current_field] << GraphQL::Current.field.path
          :thing
        end
      end

      query(Query)
      use GraphQL::Dataloader
    end

    it "returns execution information" do
      ctx = {
        current_field: [],
        current_source: [],
        current_operation_name: []
      }

      res = CurrentSchema.execute("query GetThingName { thing { name } }", context: ctx)
      assert_equal "thing", res["data"]["thing"]["name"]

      assert_equal ["GetThingName"], ctx[:current_operation_name]
      assert_equal [CurrentSchema::ThingSource], ctx[:current_source]
      assert_equal ["Query.thing", "Thing.name"], ctx[:current_field]
    end
  end
end
