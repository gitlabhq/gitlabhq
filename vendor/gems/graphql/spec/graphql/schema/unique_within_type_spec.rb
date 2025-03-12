# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::UniqueWithinType do
  describe 'encode / decode' do
    it 'Converts typename and ID to and from ID' do
      global_id = GraphQL::Schema::UniqueWithinType.encode("SomeType", 123)
      type_name, id = GraphQL::Schema::UniqueWithinType.decode(global_id)
      assert_equal("SomeType", type_name)
      assert_equal("123", id)
    end

    it "allows you specify default separator" do
      GraphQL::Schema::UniqueWithinType.default_id_separator = '|'
      global_id = GraphQL::Schema::UniqueWithinType.encode("Type-With-UUID", "250cda0e-a89d-41cf-99e1-2872d89f1100")
      type_name, id = GraphQL::Schema::UniqueWithinType.decode(global_id)
      assert_equal("Type-With-UUID", type_name)
      assert_equal("250cda0e-a89d-41cf-99e1-2872d89f1100", id)
      GraphQL::Schema::UniqueWithinType.default_id_separator = '-'
    end

    it "allows you to specify the separator" do
      custom_separator = "---"
      global_id = GraphQL::Schema::UniqueWithinType.encode("Type-With-UUID", "250cda0e-a89d-41cf-99e1-2872d89f1100", separator: custom_separator)
      type_name, id = GraphQL::Schema::UniqueWithinType.decode(global_id, separator: custom_separator)
      assert_equal("Type-With-UUID", type_name)
      assert_equal("250cda0e-a89d-41cf-99e1-2872d89f1100", id)
    end

    it "allows using the separator in the ID" do
      global_id = GraphQL::Schema::UniqueWithinType.encode("SomeUUIDType", "250cda0e-a89d-41cf-99e1-2872d89f1100")
      type_name, id = GraphQL::Schema::UniqueWithinType.decode(global_id)
      assert_equal("SomeUUIDType", type_name)
      assert_equal("250cda0e-a89d-41cf-99e1-2872d89f1100", id)
    end

    it "raises an execution error if invalid string is decoded" do
      err = assert_raises(GraphQL::ExecutionError) {
        GraphQL::Schema::UniqueWithinType.decode("Invalid-String*")
      }
      assert_includes err.message, "Invalid input: \"Invalid-String*\""
    end

    it "raises an error if you try and use a reserved character in the typename" do
      err = assert_raises(RuntimeError) {
        GraphQL::Schema::UniqueWithinType.encode("Best-Thing", "234-567")
      }
      assert_includes err.message, "encode(Best-Thing, 234-567) contains reserved characters `-` in the type name"
    end
  end
end
