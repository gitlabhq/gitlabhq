# frozen_string_literal: true
require "spec_helper"
require "generators/graphql/mutation_create_generator"

class GraphQLGeneratorsMutationCreateGeneratorTest < BaseGeneratorTest
  tests Graphql::Generators::MutationCreateGenerator

  destination File.expand_path("../../../tmp/dummy", File.dirname(__FILE__))

  setup :prepare_destination

  NAMESPACED_CREATE_NAME_MUTATION = <<-RUBY
# frozen_string_literal: true

module Mutations
  class Names::NameCreate < BaseMutation
    description "Creates a new name"

    field :name, Types::Objects::Names::NameType, null: false

    argument :name_input, Types::Inputs::Names::NameInputType, required: true

    def resolve(name_input:)
      names_name = ::Names::Name.new(**name_input)
      raise GraphQL::ExecutionError.new "Error creating name", extensions: names_name.errors.to_hash unless names_name.save

      { name: names_name }
    end
  end
end
RUBY

  CREATE_NAME_MUTATION = <<-RUBY
# frozen_string_literal: true

module Mutations
  class Names::NameCreate < BaseMutation
    description "Creates a new name"

    field :name, Types::Names::NameType, null: false

    argument :name_input, Types::Names::NameInputType, required: true

    def resolve(name_input:)
      names_name = ::Names::Name.new(**name_input)
      raise GraphQL::ExecutionError.new "Error creating name", extensions: names_name.errors.to_hash unless names_name.save

      { name: names_name }
    end
  end
end
RUBY

  EXPECTED_MUTATION_TYPE = <<-RUBY
# frozen_string_literal: true

module Types
  class MutationType < Types::BaseObject
    field :name_create, mutation: Mutations::Names::NameCreate
    # TODO: remove me
    field :test_field, String, null: false,
      description: "An example field added by the generator"
    def test_field
      "Hello World"
    end
  end
end
RUBY

  test "it generates a create resolver by name, and inserts the field into the MutationType" do
    run_generator(["names/name", "--schema", "dummy"])
    assert_file "app/graphql/mutations/names/name_create.rb", CREATE_NAME_MUTATION
    assert_file "app/graphql/types/mutation_type.rb", EXPECTED_MUTATION_TYPE
  end

  test "it generates a namespaced create resolver by name" do
    run_generator(["names/name", "--schema", "dummy", "--namespaced-types"])
    assert_file "app/graphql/mutations/names/name_create.rb", NAMESPACED_CREATE_NAME_MUTATION
  end

  test "it allows for user-specified directory" do
    run_generator(["names/name", "--schema", "dummy", "--directory", "app/mydirectory"])

    assert_file "app/mydirectory/mutations/names/name_create.rb", CREATE_NAME_MUTATION
  end
end
