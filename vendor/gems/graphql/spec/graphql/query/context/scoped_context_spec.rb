# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Query::Context::ScopedContext do
  class ScopedContextSchema < GraphQL::Schema
    class Promise
      def initialize(parent = nil, &block)
        @parent = parent
        @block = block
        @value = nil
        @children = []
      end

      def value
        @value ||= begin
          if @parent
            @parent.value
          else
            v = @block.call
            @children.each { |ch| ch.resolve_with(v) }
            v
          end
        end
      end

      def resolve_with(v)
        @value = @block.call(v)
      end

      def then(&block)
        prm = Promise.new(self, &block)
        @children << prm
        prm
      end
    end

    class Thing < GraphQL::Schema::Object
      field :name, String

      def name
        context[:thing_name]
      end

      field :name_2, String

      def name_2
        context[:thing_name_2]
      end
    end

    class ThingEdgeType < GraphQL::Schema::Object
      field :node, Thing
      def node
        scoped_ctx = context.scoped
        # Create a tree of promises, where many depend on one parent:
        prm = context[:main_promise] ||= Promise.new { :noop }
        prm.then {
          scoped_ctx.set!(:thing_name, object)
          scoped_ctx.merge!({ thing_name_2: object.to_s.upcase })
          :thing
        }
      end
    end

    class ThingConnectionType < GraphQL::Schema::Object
      field :edges, [ThingEdgeType]

      def edges
        object
      end
    end

    class Query < GraphQL::Schema::Object
      field :things, ThingConnectionType, connection: false
      def things
        [:one, :two, :three]
      end
    end

    query(Query)
    lazy_resolve(Promise, :value)
  end

  it "works with promise tree resolution and .scoped" do
    query_str = "{ things { edges { node { name name2 } } } }"
    res = ScopedContextSchema.execute(query_str)
    assert_equal "one", res["data"]["things"]["edges"][0]["node"]["name"]
    assert_equal "ONE", res["data"]["things"]["edges"][0]["node"]["name2"]
    assert_equal "two", res["data"]["things"]["edges"][1]["node"]["name"]
    assert_equal "TWO", res["data"]["things"]["edges"][1]["node"]["name2"]
    assert_equal "three", res["data"]["things"]["edges"][2]["node"]["name"]
    assert_equal "THREE", res["data"]["things"]["edges"][2]["node"]["name2"]
  end
end
