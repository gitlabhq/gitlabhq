# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Introspection::EntryPoints do
  describe "#__type" do
    let(:schema) do
      nested_invisible_type = Class.new(GraphQL::Schema::Object) do
        graphql_name 'NestedInvisible'
        field :foo, String, null: false
      end

      invisible_type = Class.new(GraphQL::Schema::Object) do
        graphql_name 'Invisible'
        field :foo, String, null: false
        field :nested_invisible, nested_invisible_type, null: false

        def self.visible?(context)
          false
        end
      end

      visible_type = Class.new(GraphQL::Schema::Object) do
        graphql_name 'Visible'
        field :foo, String, null: false
      end

      query_type = Class.new(GraphQL::Schema::Object) do
        graphql_name 'Query'
        field :foo, String, null: false
        field :invisible, invisible_type, null: false
        field :visible, visible_type, null: false
      end

      Class.new(GraphQL::Schema) do
        query query_type
        use GraphQL::Schema::Warden if ADD_WARDEN
      end
    end

    let(:query_string) {%|
      query getType($name: String!) {
        __type(name: $name) {
          name
        }
      }
    |}

    it "returns reachable types" do
      result = schema.execute(query_string, variables: { name: 'Visible' })
      type_name = result['data']['__type']['name']
      assert_equal('Visible', type_name)
    end

    it "returns nil for unreachable types" do
      result = schema.execute(query_string, variables: { name: 'NestedInvisible' })
      type_name = result['data']['__type']
      assert_nil(type_name)
    end
  end
end
