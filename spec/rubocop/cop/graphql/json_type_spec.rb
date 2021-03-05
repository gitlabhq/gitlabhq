# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../../rubocop/cop/graphql/json_type'

RSpec.describe RuboCop::Cop::Graphql::JSONType do
  let(:msg) do
    'Avoid using GraphQL::Types::JSON. See: https://docs.gitlab.com/ee/development/api_graphql_styleguide.html#json'
  end

  subject(:cop) { described_class.new }

  context 'fields' do
    it 'adds an offense when GraphQL::Types::JSON is used' do
      expect_offense(<<~RUBY)
        class MyType
          field :some_field, GraphQL::Types::JSON
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
        end
      RUBY
    end

    it 'adds an offense when GraphQL::Types::JSON is used with other keywords' do
      expect_offense(<<~RUBY)
        class MyType
          field :some_field, GraphQL::Types::JSON, null: true, description: 'My description'
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
        end
      RUBY
    end

    it 'does not add an offense for other types' do
      expect_no_offenses(<<~RUBY.strip)
        class MyType
          field :some_field, GraphQL::STRING_TYPE
        end
      RUBY
    end
  end

  context 'arguments' do
    it 'adds an offense when GraphQL::Types::JSON is used' do
      expect_offense(<<~RUBY)
        class MyType
          argument :some_arg, GraphQL::Types::JSON
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
        end
      RUBY
    end

    it 'adds an offense when GraphQL::Types::JSON is used with other keywords' do
      expect_offense(<<~RUBY)
        class MyType
          argument :some_arg, GraphQL::Types::JSON, null: true, description: 'My description'
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
        end
      RUBY
    end

    it 'does not add an offense for other types' do
      expect_no_offenses(<<~RUBY.strip)
        class MyType
          argument :some_arg, GraphQL::STRING_TYPE
        end
      RUBY
    end
  end

  it 'does not add an offense for uses outside of field or argument' do
    expect_no_offenses(<<~RUBY.strip)
      class MyType
        foo :some_field, GraphQL::Types::JSON
      end
    RUBY
  end
end
