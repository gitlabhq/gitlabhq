# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Pagination::Connections do
  ITEMS = ConnectionAssertions::NAMES.map { |n| { name: n } }

  class ArrayConnectionWithTotalCount < GraphQL::Pagination::ArrayConnection
    def total_count
      items.size
    end
  end

  let(:base_schema) {
    ConnectionAssertions.build_schema(
      connection_class: GraphQL::Pagination::ArrayConnection,
      total_count_connection_class: ArrayConnectionWithTotalCount,
      get_items: -> { ITEMS }
    )
  }

  # These wouldn't _work_, I just need to test `.wrap`
  class SetConnection < GraphQL::Pagination::ArrayConnection; end
  class HashConnection < GraphQL::Pagination::ArrayConnection; end
  class OtherArrayConnection < GraphQL::Pagination::ArrayConnection; end

  let(:schema) do
    other_base_schema = Class.new(base_schema) do
      connections.add(Set, SetConnection)
    end

    Class.new(other_base_schema) do
      connections.add(Hash, HashConnection)
      connections.add(Array, OtherArrayConnection)
    end
  end

  it "returns connections by class, using inherited mappings and local overrides" do
    field_defn = OpenStruct.new(has_max_page_size?: true, max_page_size: 10, has_default_page_size?: true, default_page_size: 5, type: GraphQL::Types::Relay::BaseConnection)

    set_wrapper = schema.connections.wrap(field_defn, nil, Set.new([1,2,3]), {}, nil)
    assert_instance_of SetConnection, set_wrapper

    hash_wrapper = schema.connections.wrap(field_defn, nil, {1 => :a, 2 => :b}, {}, nil)
    assert_instance_of HashConnection, hash_wrapper

    array_wrapper = schema.connections.wrap(field_defn, nil, [1,2,3], {}, nil)
    assert_instance_of OtherArrayConnection, array_wrapper

    raw_value = schema.connections.wrap(field_defn, nil, GraphQL::Execution::Interpreter::RawValue.new([1,2,3]), {}, nil)
    assert_instance_of GraphQL::Execution::Interpreter::RawValue, raw_value
  end

  it "uses cached wrappers" do
    field_defn = OpenStruct.new(max_page_size: 10)
    dummy_ctx = Class.new do
      def namespace(some_key)
        if some_key == :connections
          { all_wrappers: {} }
        else
          raise ArgumentError, "unsupported key: #{some_key.inspect}"
        end
      end
    end
    assert_raises GraphQL::Pagination::Connections::ImplementationMissingError do
      schema.connections.wrap(field_defn, nil, Set.new([1,2,3]), {}, dummy_ctx.new)
    end
  end

  # Simulate a schema with a `*Connection` type that _isn't_
  # supposed to be a connection. Help debug, see https://github.com/rmosolgo/graphql-ruby/issues/2588
  class ConnectionErrorTestSchema < GraphQL::Schema
    class BadThing
      def name
        self.no_such_method # raise a NoMethodError
      end

      def inspect
        "<BadThing!>"
      end
    end

    class ThingConnection < GraphQL::Schema::Object
      field :name, String, null: false
    end

    class Query < GraphQL::Schema::Object
      field :things, [ThingConnection], null: false

      def things
        [{name: "thing1"}, {name: "thing2"}]
      end

      field :things2, [ThingConnection], null: false, connection: false

      def things2
        [
          BadThing.new
        ]
      end
    end

    query(Query)
  end

  it "raises a helpful error when it fails to implement a connection" do
    err = assert_raises GraphQL::Execution::Interpreter::ListResultFailedError do
      pp ConnectionErrorTestSchema.execute("{ things { name } }")
    end

    assert_includes err.message, "Failed to build a GraphQL list result for field `Query.things` at path `things`."
    assert_includes err.message, "(GraphQL::Pagination::ArrayConnection) to implement `.each` to satisfy the GraphQL return type `[ThingConnection!]!`"
    assert_includes err.message, "This field was treated as a Relay-style connection; add `connection: false` to the `field(...)` to disable this behavior."
  end

  it "lets unrelated NoMethodErrors bubble up" do
    err = assert_raises NoMethodError do
      ConnectionErrorTestSchema.execute("{ things2 { name } }")
    end

    expected_message = if RUBY_VERSION >= "3.4"
      "undefined method 'no_such_method' for an instance of ConnectionErrorTestSchema::BadThing"
    elsif RUBY_VERSION >= "3.3"
      "undefined method `no_such_method' for an instance of ConnectionErrorTestSchema::BadThing"
    else
      "undefined method `no_such_method' for <BadThing!>"
    end

    assert_includes err.message, expected_message
  end

  it "uses a field's `max_page_size: nil` configuration" do
    user_type = Class.new(GraphQL::Schema::Object) do
      graphql_name 'User'
      field :name, String, null: false
    end

    query_type = Class.new(GraphQL::Schema::Object) do
      graphql_name 'Query'
      field :users, user_type.connection_type, max_page_size: nil
      def users
        [{ name: 'Yoda' }, { name: 'Anakin' }, { name: 'Obi Wan' }]
      end
    end

    schema = Class.new(GraphQL::Schema) do
      # This value should be overridden by `max_page_size: nil` in the field definition above
      default_max_page_size 2
      query(query_type)
    end

    res = schema.execute(<<-GRAPHQL).to_h
      {
        users {
          nodes {
            name
          }
        }
      }
    GRAPHQL

    assert_equal ["Yoda", "Anakin", "Obi Wan"], res['data']['users']['nodes'].map { |node| node['name'] }
  end

  class SingleNewConnectionSchema < GraphQL::Schema
    class Query < GraphQL::Schema::Object
      field :strings, GraphQL::Types::String.connection_type, null: false

      def strings
        GraphQL::Pagination::ArrayConnection.new(["a", "b", "c"])
      end
    end

    query(Query)
  end

  it "works when new connections are not installed" do
    res = SingleNewConnectionSchema.execute("{ strings(first: 2) { edges { node } } }")
    assert_equal ["a", "b"], res["data"]["strings"]["edges"].map { |e| e["node"] }
  end
end
