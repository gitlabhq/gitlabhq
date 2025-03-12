# frozen_string_literal: true
require "spec_helper"
require "generators/graphql/mutation_generator"
require "generators/graphql/install_generator"

class GraphQLGeneratorsMutationGeneratorTest < BaseGeneratorTest
  tests Graphql::Generators::MutationGenerator

  setup :prepare_destination

  UPDATE_NAME_MUTATION = <<-RUBY
# frozen_string_literal: true

module Mutations
  class UpdateName < BaseMutation
    # TODO: define return fields
    # field :post, Types::PostType, null: false

    # TODO: define arguments
    # argument :name, String, required: true

    # TODO: define resolve method
    # def resolve(name:)
    #   { post: ... }
    # end
  end
end
RUBY

  EXPECTED_MUTATION_TYPE = <<-RUBY
# frozen_string_literal: true

module Types
  class MutationType < Types::BaseObject
    field :update_name, mutation: Mutations::UpdateName
    # TODO: remove me
    field :test_field, String, null: false,
      description: "An example field added by the generator"
    def test_field
      "Hello World"
    end
  end
end
RUBY

  NAMESPACED_UPDATE_NAME_MUTATION = <<-RUBY
# frozen_string_literal: true

module Mutations
  class Names::UpdateName < BaseMutation
    # TODO: define return fields
    # field :post, Types::PostType, null: false

    # TODO: define arguments
    # argument :name, String, required: true

    # TODO: define resolve method
    # def resolve(name:)
    #   { post: ... }
    # end
  end
end
RUBY

  NAMESPACED_EXPECTED_MUTATION_TYPE = <<-RUBY
# frozen_string_literal: true

module Types
  class MutationType < Types::BaseObject
    field :update_name, mutation: Mutations::Names::UpdateName
    # TODO: remove me
    field :test_field, String, null: false,
      description: "An example field added by the generator"
    def test_field
      "Hello World"
    end
  end
end
RUBY

  test "it generates an empty resolver by name and inserts the field into the MutationType" do
    run_generator(["UpdateName", "--schema", "dummy"])
    assert_file "app/graphql/mutations/update_name.rb", UPDATE_NAME_MUTATION
    assert_file "app/graphql/types/mutation_type.rb", EXPECTED_MUTATION_TYPE
  end

  test "it generates and inserts a namespaced resolver" do
    run_generator(["names/update_name", "--schema", "dummy"])
    assert_file "app/graphql/mutations/names/update_name.rb", NAMESPACED_UPDATE_NAME_MUTATION
    assert_file "app/graphql/types/mutation_type.rb", NAMESPACED_EXPECTED_MUTATION_TYPE
  end

  test "it allows for user-specified directory" do
    run_generator(["UpdateName", "--schema", "dummy", "--directory", "app/mydirectory"])

    assert_file "app/mydirectory/mutations/update_name.rb", UPDATE_NAME_MUTATION
  end
end
