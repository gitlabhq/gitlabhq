# frozen_string_literal: true
require "spec_helper"
require "generators/graphql/mutation_delete_generator"

class GraphQLGeneratorsMutationDeleteGeneratorTest < BaseGeneratorTest
  tests Graphql::Generators::MutationDeleteGenerator

  destination File.expand_path("../../../tmp/dummy", File.dirname(__FILE__))

  setup :prepare_destination

  # Use this to account for `.destroy` vs `.destroy!` in https://github.com/rails/rails/pull/43501
  example_orm_instance = Rails::Generators::ActiveModel.new "names_name"

  NAMESPACED_DELETE_NAME_MUTATION = <<-RUBY
# frozen_string_literal: true

module Mutations
  class Names::NameDelete < BaseMutation
    description "Deletes a name by ID"

    field :name, Types::Objects::Names::NameType, null: false

    argument :id, ID, required: true

    def resolve(id:)
      names_name = ::Names::Name.find(id)
      raise GraphQL::ExecutionError.new "Error deleting name", extensions: names_name.errors.to_hash unless #{example_orm_instance.destroy}

      { name: names_name }
    end
  end
end
RUBY

  DELETE_NAME_MUTATION = <<-RUBY
# frozen_string_literal: true

module Mutations
  class Names::NameDelete < BaseMutation
    description "Deletes a name by ID"

    field :name, Types::Names::NameType, null: false

    argument :id, ID, required: true

    def resolve(id:)
      names_name = ::Names::Name.find(id)
      raise GraphQL::ExecutionError.new "Error deleting name", extensions: names_name.errors.to_hash unless #{example_orm_instance.destroy}

      { name: names_name }
    end
  end
end
RUBY

  EXPECTED_DELETE_MUTATION_TYPE = <<-RUBY
# frozen_string_literal: true

module Types
  class MutationType < Types::BaseObject
    field :name_delete, mutation: Mutations::Names::NameDelete
    # TODO: remove me
    field :test_field, String, null: false,
      description: "An example field added by the generator"
    def test_field
      "Hello World"
    end
  end
end
RUBY

  test "it generates a delete resolver by name, and inserts the field into the MutationType" do
    run_generator(["names/name", "--schema", "dummy"])
    assert_file "app/graphql/mutations/names/name_delete.rb", DELETE_NAME_MUTATION
    assert_file "app/graphql/types/mutation_type.rb", EXPECTED_DELETE_MUTATION_TYPE
  end

  test "it generates a namespaced delete resolver by name" do
    run_generator(["names/name", "--schema", "dummy", "--namespaced-types"])
    assert_file "app/graphql/mutations/names/name_delete.rb", NAMESPACED_DELETE_NAME_MUTATION
  end

  test "it allows for user-specified directory, delete" do
    run_generator(["names/name", "--schema", "dummy", "--directory", "app/mydirectory"])

    assert_file "app/mydirectory/mutations/names/name_delete.rb", DELETE_NAME_MUTATION
  end
end
