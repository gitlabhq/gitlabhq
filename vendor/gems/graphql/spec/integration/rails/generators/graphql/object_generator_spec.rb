# frozen_string_literal: true
require "spec_helper"
require "generators/graphql/object_generator"

class GraphQLGeneratorsObjectGeneratorTest < BaseGeneratorTest
  tests Graphql::Generators::ObjectGenerator

  # rubocop:disable Style/ClassAndModuleChildren
  class ::TestUser < ActiveRecord::Base
  end
  # rubocop:enable Style/ClassAndModuleChildren

  test "it generates fields with types" do
    commands = [
      # GraphQL-style:
      ["Bird", "wingspan:Int!", "foliage:[Color]"],
      # Ruby-style:
      ["BirdType", "wingspan:!Integer", "foliage:[Types::ColorType]"],
      # Mixed
      ["BirdType", "wingspan:!Int", "foliage:[Color]"],
    ]

    expected_content = <<-RUBY
# frozen_string_literal: true

module Types
  class BirdType < Types::BaseObject
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
      ["Bird", "wingspan:Int!", "foliage:[Color]"],
      # Ruby-style:
      ["BirdType", "wingspan:!Integer", "foliage:[Types::ColorType]"],
      # Mixed
      ["BirdType", "wingspan:!Int", "foliage:[Color]"],
    ].map { |c| c + ["--namespaced-types"]}

    expected_content = <<-RUBY
# frozen_string_literal: true

module Types
  class Objects::BirdType < Types::BaseObject
    field :wingspan, Integer, null: false
    field :foliage, [Types::ColorType]
  end
end
RUBY

    commands.each do |c|
      prepare_destination
      run_generator(c)
      assert_file "app/graphql/types/objects/bird_type.rb", expected_content
    end
  end

  test "it generates namespaced classified file" do
    run_generator(["books/page"])
    assert_file "app/graphql/types/books/page_type.rb", <<-RUBY
# frozen_string_literal: true

module Types
  class Books::PageType < Types::BaseObject
  end
end
RUBY
  end

  test "it makes Relay nodes" do
    run_generator(["Page", "--node"])
    assert_file "app/graphql/types/page_type.rb", <<-RUBY
# frozen_string_literal: true

module Types
  class PageType < Types::BaseObject
    implements GraphQL::Types::Relay::Node
  end
end
RUBY
  end

  test "it generates objects based on ActiveRecord schema, with namespaced types" do
    run_generator(["TestUser", "--namespaced-types"])
    assert_file "app/graphql/types/objects/test_user_type.rb", <<-RUBY
# frozen_string_literal: true

module Types
  class Objects::TestUserType < Types::BaseObject
    field :id, ID, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime
    field :birthday, GraphQL::Types::ISO8601Date
    field :points, Integer, null: false
    field :rating, Float, null: false
  end
end
RUBY
  end

  test "it generates objects based on ActiveRecord schema with additional custom fields" do
    run_generator(["TestUser", "name:!String", "email:!Citext", "settings:jsonb"])
    assert_file "app/graphql/types/test_user_type.rb", <<-RUBY
# frozen_string_literal: true

module Types
  class TestUserType < Types::BaseObject
    field :id, ID, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime
    field :birthday, GraphQL::Types::ISO8601Date
    field :points, Integer, null: false
    field :rating, Float, null: false
    field :name, String, null: false
    field :email, String, null: false
    field :settings, GraphQL::Types::JSON
  end
end
RUBY
  end
end
