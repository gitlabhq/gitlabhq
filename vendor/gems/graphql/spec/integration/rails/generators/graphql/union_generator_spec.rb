# frozen_string_literal: true
require "spec_helper"
require "generators/graphql/union_generator"

class GraphQLGeneratorsUnionGeneratorTest < BaseGeneratorTest
  tests Graphql::Generators::UnionGenerator

  test "it generates a union with possible types" do
    commands = [
      # GraphQL-style:
      ["WingedCreature", "Insect", "Bird"],
      # Ruby-style:
      ["Types::WingedCreatureType", "Types::InsectType", "Types::BirdType"],
    ]

    expected_content = <<-RUBY
# frozen_string_literal: true

module Types
  class WingedCreatureType < Types::BaseUnion
    possible_types Types::InsectType, Types::BirdType
  end
end
RUBY

    commands.each do |c|
      prepare_destination
      run_generator(c)
      assert_file "app/graphql/types/winged_creature_type.rb", expected_content
    end
  end

  test "it generates an union with possible namespaced types" do
    commands = [
      # GraphQL-style:
      ["WingedCreature", "Insect", "Bird"],
      # Ruby-style:
      ["Types::WingedCreatureType", "Types::InsectType", "Types::BirdType"],
    ].map { |c| c + ["--namespaced-types"]}

    expected_content = <<-RUBY
# frozen_string_literal: true

module Types
  class Unions::WingedCreatureType < Types::BaseUnion
    possible_types Types::InsectType, Types::BirdType
  end
end
RUBY

    commands.each do |c|
      prepare_destination
      run_generator(c)
      assert_file "app/graphql/types/unions/winged_creature_type.rb", expected_content
    end
  end


  test "it accepts a user-specified directory" do
    command = ["WingedCreature", "--directory", "app/mydirectory"]

    expected_content = <<-RUBY
# frozen_string_literal: true

module Types
  class WingedCreatureType < Types::BaseUnion
  end
end
RUBY

    prepare_destination
    run_generator(command)
    assert_file "app/mydirectory/types/winged_creature_type.rb", expected_content
  end
end
