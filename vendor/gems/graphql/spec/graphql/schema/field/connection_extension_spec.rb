# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Field::ConnectionExtension do
  class ConnectionShortcutSchema < GraphQL::Schema
    class ShortcutResolveExtension < GraphQL::Schema::FieldExtension
      def resolve(arguments:, **rest)
        collection = ["a", "b", "c", "d", "e"]
        if (filter = arguments[:starting_with])
          collection.select! { |x| x.start_with?(filter) }
        end
        collection
      end
    end

    class CustomStringConnection < GraphQL::Types::Relay::BaseConnection
      edge_type(GraphQL::Types::String.edge_type)
      field :argument_data, [String], null: false

      def argument_data
        [object.arguments.class.name, *object.arguments.keys.map(&:inspect).sort]
      end
    end

    class Query < GraphQL::Schema::Object
      field :names, CustomStringConnection, null: false, extensions: [ShortcutResolveExtension] do
        argument :starting_with, String, required: false
      end

      def names
        raise "This should never be called"
      end
    end

    query(Query)
  end

  it "implements connection handling even when resolve is shortcutted" do
    res = ConnectionShortcutSchema.execute("{ names(first: 2) { nodes } }")
    assert_equal ["a", "b"], res["data"]["names"]["nodes"]
  end

  it "assigns arguments to the connection instance" do
    res = ConnectionShortcutSchema.execute("{ names(first: 2, startingWith: \"a\") { nodes argumentData } }")
    assert_equal ["a"], res["data"]["names"]["nodes"]
    # This come through as symbols
    assert_equal ["Hash", ":first", ":starting_with"], res["data"]["names"]["argumentData"]
  end
end
