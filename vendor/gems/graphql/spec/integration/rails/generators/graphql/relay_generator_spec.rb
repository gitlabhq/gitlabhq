# frozen_string_literal: true
require "spec_helper"
require "generators/graphql/relay_generator"
require "generators/graphql/install_generator"

class GraphQLGeneratorsRelayGeneratorTest < Rails::Generators::TestCase
  tests Graphql::Generators::RelayGenerator
  destination File.expand_path("../../../tmp/dummy", File.dirname(__FILE__))

  setup do
    prepare_destination
    FileUtils.cd(File.join(destination_root, '..')) do
      `rails new dummy --skip-active-record --skip-test-unit --skip-spring --skip-bundle --skip-webpack-install`
      Graphql::Generators::InstallGenerator.start(["--skip-graphiql"], { destination_root: destination_root })
    end
  end


  test "it adds node and connection stuff" do
    run_generator

    assert_file "app/graphql/types/node_type.rb" do |content|
      assert_includes content, "module NodeType"
      assert_includes content, "include Types::BaseInterface"
      assert_includes content, "include GraphQL::Types::Relay::NodeBehaviors"
    end

    assert_file "app/graphql/types/base_connection.rb" do |content|
      assert_includes content, "class BaseConnection < Types::BaseObject"
      assert_includes content, "include GraphQL::Types::Relay::ConnectionBehaviors"
    end

    assert_file "app/graphql/types/base_edge.rb" do |content|
      assert_includes content, "class BaseEdge < Types::BaseObject"
      assert_includes content, "include GraphQL::Types::Relay::EdgeBehaviors"
    end

    base_return_types = [
      "app/graphql/types/base_union.rb",
      "app/graphql/types/base_interface.rb",
      "app/graphql/types/base_object.rb",
    ]

    base_return_types.each do |base_type_path|
      assert_file base_type_path do |content|
        assert_includes content, "connection_type_class(Types::BaseConnection)", "#{base_type_path} has base connection setup"
        assert_includes content, "edge_type_class(Types::BaseEdge)", "#{base_type_path} has base edge setup"
      end
    end

    assert_file "app/graphql/types/query_type.rb" do |content|
      assert_includes content, "field :node, Types::NodeType"
      assert_includes content, "field :nodes, [Types::NodeType, null: true]"
    end

    assert_file "app/graphql/dummy_schema.rb" do |content|
      assert_includes content, "def self.object_from_id"
    end
  end
end
