# frozen_string_literal: true
require "spec_helper"
require "generators/graphql/interface_generator"

class GraphQLGeneratorsInterfaceGeneratorTest < BaseGeneratorTest
  tests Graphql::Generators::InterfaceGenerator

  test "it generates fields with types" do
    commands = [
      # GraphQL-style:
      ["Bird", "wingspan:Int!", "foliage:[Color]"],
      # Ruby-style:
      ["BirdType", "wingspan:Integer!", "foliage:[Types::ColorType]"],
      # Mixed
      ["BirdType", "wingspan:!Int", "foliage:[Color]"],
    ]

    expected_content = <<-RUBY
# frozen_string_literal: true

module Types
  module BirdType
    include Types::BaseInterface
    field :wingspan, Integer, null: false
    field :foliage, [Types::ColorType]
  end
end
RUBY

    commands.each do |c|
      prepare_destination
      run_generator(c)
      assert_file "app/graphql/types/bird_type.rb", expected_content
    end
  end

  test "it generates fields with namespaced types" do
    commands = [
      # GraphQL-style:
      ["animals/Bird", "wingspan:Int!", "foliage:[Color]"],
      # Ruby-style:
      ["animals/BirdType", "wingspan:Integer!", "foliage:[Types::ColorType]"],
      # Mixed
      ["animals/BirdType", "wingspan:!Int", "foliage:[Color]"],
    ].map { |c| c + ["--namespaced-types"]}

    expected_content = <<-RUBY
# frozen_string_literal: true

module Types
  module Interfaces::Animals::BirdType
    include Types::BaseInterface
    field :wingspan, Integer, null: false
    field :foliage, [Types::ColorType]
  end
end
RUBY

    commands.each do |c|
      prepare_destination
      run_generator(c)
      assert_file "app/graphql/types/interfaces/animals/bird_type.rb", expected_content
    end
  end
end
