# frozen_string_literal: true
require "spec_helper"

rake_task_schema_defn = <<-GRAPHQL
type Query {
  allowed(allowed: ID!, excluded: ID!): Int
  excluded(excluded: ID!): Boolean
  ignored(input: NotOneOf): Float
}

input NotOneOf {
  arg: Int,
}
GRAPHQL

RakeTaskSchema = GraphQL::Schema.from_definition(rake_task_schema_defn)

class FilteredRakeTaskSchema < RakeTaskSchema
  def self.visible?(member, ctx)
    (
      member.is_a?(Class) &&
        member < GraphQL::Schema::Scalar &&
        # Warden doesn't include these for some reason:
        !(member.graphql_name.start_with?("Boolean", "String"))
    ) || (
      ctx[:filtered] && ["Query", "allowed"].include?(member.graphql_name)
    ) || (
      member.respond_to?(:introspection?) && member.introspection?
    ) || (
      member.respond_to?(:owner) && member.owner.introspection?
    )
  end
end

# Default task
GraphQL::RakeTask.new(schema_name: "RakeTaskSchema")
# Configured task
GraphQL::RakeTask.new(idl_outfile: "tmp/configured_schema.graphql") do |t|
  t.namespace = "graphql_custom"
  t.load_context = ->(task) { {filtered: true } }
  t.load_schema = ->(task) { FilteredRakeTaskSchema }
end

GraphQL::RakeTask.new(namespace: "custom_json", schema_name: "RakeTaskSchema", json_outfile: "tmp/custom_json.json", include_is_one_of: true, include_is_repeatable: true, include_specified_by_url: true)

describe GraphQL::RakeTask do
  describe "default settings" do
    after do
      FileUtils.rm_rf("./schema.json")
      FileUtils.rm_rf("./schema.graphql")
    end

    it "writes JSON" do
      capture_io do
        Rake::Task["graphql:schema:dump"].invoke
      end
      dumped_json = File.read("./schema.json")
      expected_json = JSON.pretty_generate(RakeTaskSchema.execute(GraphQL::Introspection.query(include_deprecated_args: true)))

      # Test that that JSON is logically equivalent, not serialized the same
      assert_equal(JSON.parse(expected_json), JSON.parse(dumped_json))
      # This was dumped with default options, so these are not present:
      refute_includes dumped_json, "\"isOneOf\": "
      refute_includes dumped_json, "\"specifiedByURL\": "
      refute_includes dumped_json, "\"isRepeatable\": "

      dumped_idl = File.read("./schema.graphql")
      expected_idl = RakeTaskSchema.to_definition
      assert_equal(expected_idl, dumped_idl, "The rake task output and #to_definition output match")
    end
  end

  describe "customized settings" do
    it "writes GraphQL" do
      capture_io do
        Rake::Task["graphql_custom:schema:idl"].invoke
      end
      dumped_idl = File.read("./tmp/configured_schema.graphql")
      expected_idl = "type Query {
  allowed(allowed: ID!): Int
}
"
      assert_equal expected_idl, dumped_idl
    end

    it "writes JSON" do
      capture_io do
        Rake::Task["custom_json:schema:json"].invoke
      end

      dumped_json = File.read("./tmp/custom_json.json")

      assert_includes dumped_json, "\"isOneOf\": "
      assert_includes dumped_json, "\"specifiedByURL\": "
      assert_includes dumped_json, "\"isRepeatable\": "
    end
  end
end
