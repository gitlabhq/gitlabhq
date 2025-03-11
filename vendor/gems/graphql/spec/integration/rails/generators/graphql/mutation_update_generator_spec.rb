# frozen_string_literal: true
require "spec_helper"
require "generators/graphql/mutation_update_generator"

class GraphQLGeneratorsMutationUpdateGeneratorTest < BaseGeneratorTest
  tests Graphql::Generators::MutationUpdateGenerator

  destination File.expand_path("../../../tmp/dummy", File.dirname(__FILE__))

  setup :prepare_destination

  NAMESPACED_UPDATE_NAME_MUTATION = <<-RUBY
# frozen_string_literal: true

module Mutations
  class Names::NameUpdate < BaseMutation
    description "Updates a name by id"

    field :name, Types::Objects::Names::NameType, null: false

    argument :id, ID, required: true
    argument :name_input, Types::Inputs::Names::NameInputType, required: true

    def resolve(id:, name_input:)
      names_name = ::Names::Name.find(id)
      raise GraphQL::ExecutionError.new "Error updating name", extensions: names_name.errors.to_hash unless names_name.update(**name_input)

      { name: names_name }
    end
  end
end
RUBY

  UPDATE_NAME_MUTATION = <<-RUBY
# frozen_string_literal: true

module Mutations
  class Names::NameUpdate < BaseMutation
    description "Updates a name by id"

    field :name, Types::Names::NameType, null: false

    argument :id, ID, required: true
    argument :name_input, Types::Names::NameInputType, required: true

    def resolve(id:, name_input:)
      names_name = ::Names::Name.find(id)
      raise GraphQL::ExecutionError.new "Error updating name", extensions: names_name.errors.to_hash unless names_name.update(**name_input)

      { name: names_name }
    end
  end
end
RUBY

  EXPECTED_UPDATE_MUTATION_TYPE = <<-RUBY
# frozen_string_literal: true

module Types
  class MutationType < Types::BaseObject
    field :name_update, mutation: Mutations::Names::NameUpdate
    # TODO: remove me
    field :test_field, String, null: false,
      description: "An example field added by the generator"
    def test_field
      "Hello World"
    end
  end
end
RUBY

  test "it generates an update resolver by name, and inserts the field into the MutationType" do
    run_generator(["names/name", "--schema", "dummy"])
    assert_file "app/graphql/mutations/names/name_update.rb", UPDATE_NAME_MUTATION
    assert_file "app/graphql/types/mutation_type.rb", EXPECTED_UPDATE_MUTATION_TYPE
  end

  test "it generates a namespaced update resolver by name" do
    run_generator(["names/name", "--schema", "dummy", "--namespaced-types"])
    assert_file "app/graphql/mutations/names/name_update.rb", NAMESPACED_UPDATE_NAME_MUTATION
  end

  test "it allows for user-specified directory, update" do
    run_generator(["names/name", "--schema", "dummy", "--directory", "app/mydirectory"])

    assert_file "app/mydirectory/mutations/names/name_update.rb", UPDATE_NAME_MUTATION
  end
end
