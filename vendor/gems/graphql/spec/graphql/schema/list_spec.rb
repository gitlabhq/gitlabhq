# frozen_string_literal: true

require "spec_helper"

describe GraphQL::Schema::List do
  let(:of_type) { Jazz::Musician }
  let(:list_type) { GraphQL::Schema::List.new(of_type) }

  it "returns list? to be true" do
    assert list_type.list?
  end

  it "returns non_null? to be false" do
    refute list_type.non_null?
  end

  it "returns kind to be GraphQL::TypeKinds::LIST" do
    assert_equal GraphQL::TypeKinds::LIST, list_type.kind
  end

  it "returns correct type signature" do
    assert_equal "[Musician]", list_type.to_type_signature
  end

  describe "comparison operator" do
    it "will return false if list types 'of_type' are different" do
      new_of_type = Jazz::InspectableKey
      new_list_type = GraphQL::Schema::List.new(new_of_type)

      refute_equal list_type, new_list_type
    end

    it "will return true if list types 'of_type' are the same" do
      new_of_type = Jazz::Musician
      new_list_type = GraphQL::Schema::List.new(new_of_type)

      assert_equal list_type, new_list_type
    end
  end

  describe "handling null" do
    class ListNullHandlingSchema < GraphQL::Schema
      class Query < GraphQL::Schema::Object
        field :strings, [String, null: true] do
          argument :strings, [String, null: true], required: false
        end

        def strings(strings:)
          strings
        end
      end
      query(Query)
    end

    it "passes `nil` as `nil`" do
      str = "query($strings: [String]){ strings(strings: $strings) }"
      res = ListNullHandlingSchema.execute(str, variables: { strings: nil })
      assert_nil res["data"]["strings"]
    end
  end

  it "Accepts \"\" as a default value from introspection" do
    schema = GraphQL::Schema.from_definition <<-GRAPHQL
    type Query {
      f(arg: [String] = ""): String
    }
    GRAPHQL
    assert_equal "", schema.query.fields["f"].arguments["arg"].default_value

    introspection_json = schema.as_json
    assert_equal '[""]', introspection_json["data"]["__schema"]["types"].find { |t| t["name"] == "Query" }["fields"].first["args"].first["defaultValue"]

    schema_2 = GraphQL::Schema.from_introspection(introspection_json)

    # since this one is from introspection, it gets a wrapped list as default value:
    assert_equal [""], schema_2.query.fields["f"].arguments["arg"].default_value
    assert_equal '[""]', schema_2.as_json["data"]["__schema"]["types"].find { |t| t["name"] == "Query" }["fields"].first["args"].first["defaultValue"]
  end

  describe "validation" do
    class ListValidationSchema < GraphQL::Schema
      class Item < GraphQL::Schema::Enum
        value "A"
        value "B"
      end

      class ItemInput < GraphQL::Schema::InputObject
        argument :item, Item
      end

      class NilItemsInput < GraphQL::Schema::InputObject
        argument :items, [Item], required: false
      end

      class Query < GraphQL::Schema::Object
        field :echo, [Item], null: false do
          argument :items, [Item]
        end

        def echo(items:)
          items
        end

        field :echoes, [Item], null: false do
          argument :items, [ItemInput]
        end

        def echoes(items:)
          items.map { |i| i[:item] }
        end

        field :nil_echoes, [Item, null: true] do
          argument :items, [NilItemsInput], required: false
        end

        def nil_echoes(items:)
          items.first[:items]
        end
      end

      query(Query)
    end

    it "checks non-null lists of enums" do
      res = ListValidationSchema.execute "{ echo(items: [A, B, \"C\"]) }"
      expected_error = "Argument 'items' on Field 'echo' has an invalid value ([A, B, \"C\"]). Expected type '[Item!]!'."
      assert_equal [expected_error], res["errors"].map { |e| e["message"] }
    end

    it "works with #valid_input?" do
      assert ListValidationSchema::Item.to_list_type.valid_isolated_input?(["A", "B"])
      refute ListValidationSchema::Item.to_list_type.valid_isolated_input?(["A", "B", "C"])
    end

    it "coerces single-item lists of input objects" do
      results = {
        "default value" => ListValidationSchema.execute("query($items: [ItemInput!] = {item: A}) { echoes(items: $items) }"),
        "literal value" => ListValidationSchema.execute("{ echoes(items: { item: A }) }"),
        "variable value" => ListValidationSchema.execute("query($items: [ItemInput!]!) { echoes(items: $items) }", variables: { items: { item: "A" } }),
      }

      results.each do |r_desc, r|
        assert_equal({"data" => { "echoes" => ["A"]}}, r, "It works for #{r_desc}")
      end
    end

    it "doesn't coerce nil into a list" do
      nil_result = ListValidationSchema.execute("query($items: [NilItemsInput!]) { nilEchoes(items: $items) }", variables: { items: { items: nil } })
      assert_equal({"data" => { "nilEchoes" => nil}}, nil_result, "It works for nil")\
    end
  end

  describe "when max validation errors exists" do
    class MaxValidationSchema < GraphQL::Schema
      class Item < GraphQL::Schema::Enum
        value "A"
        value "B"
      end

      class Query < GraphQL::Schema::Object
        field :items, [Item], null: false do
          argument :ids, [Int]
        end

        def items(ids:)
          items
        end
      end

      query(Query)
      validate_max_errors(2)
    end

    it "checks only for 2 errors and appends too many errors in the message" do
      res = MaxValidationSchema.execute("query($ids: [Int!]!) { items(ids: $ids) }", variables: { ids: ["1", "2", "3", "4"] })

      expected_error = "Variable $ids of type [Int!]! was provided invalid value for 0 "\
        "(Could not coerce value \"1\" to Int), 1 (Could not coerce value \"2\" to Int),  "\
        "(Too many errors processing list variable, max validation error limit reached. Execution aborted)"
      assert_equal [expected_error], res["errors"].map { |e| e["message"] }
    end

    it "raises only 1 error with max_validation + 1 problems" do
      res = MaxValidationSchema.execute("query($ids: [Int!]!) { items(ids: $ids) }", variables: { ids: ["1", "2", "3", "4"] })

      assert_equal 1, res["errors"].count
      assert_equal 3, res["errors"][0]["extensions"]["problems"].count
    end
  end
end
