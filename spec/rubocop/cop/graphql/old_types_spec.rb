# frozen_string_literal: true

require 'fast_spec_helper'
require 'rspec-parameterized'
require_relative '../../../../rubocop/cop/graphql/old_types'

RSpec.describe RuboCop::Cop::Graphql::OldTypes do
  using RSpec::Parameterized::TableSyntax

  subject(:cop) { described_class.new }

  where(:old_type, :message) do
    'GraphQL::ID_TYPE'      | 'Avoid using GraphQL::ID_TYPE. Use GraphQL::Types::ID instead'
    'GraphQL::INT_TYPE'     | 'Avoid using GraphQL::INT_TYPE. Use GraphQL::Types::Int instead'
    'GraphQL::STRING_TYPE'  | 'Avoid using GraphQL::STRING_TYPE. Use GraphQL::Types::String instead'
    'GraphQL::BOOLEAN_TYPE' | 'Avoid using GraphQL::BOOLEAN_TYPE. Use GraphQL::Types::Boolean instead'
  end

  with_them do
    context 'fields' do
      it 'adds an offense when an old type is used' do
        expect_offense(<<~RUBY)
        class MyType
          field :some_field, #{old_type}
          ^^^^^^^^^^^^^^^^^^^#{'^' * old_type.length} #{message}
        end
        RUBY
      end

      it "adds an offense when an old type is used with other keywords" do
        expect_offense(<<~RUBY)
        class MyType
          field :some_field, #{old_type}, null: true, description: 'My description'
          ^^^^^^^^^^^^^^^^^^^#{'^' * old_type.length}^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{message}
        end
        RUBY
      end
    end

    context 'arguments' do
      it 'adds an offense when an old type is used' do
        expect_offense(<<~RUBY)
        class MyType
          field :some_arg, #{old_type}
          ^^^^^^^^^^^^^^^^^#{'^' * old_type.length} #{message}
        end
        RUBY
      end

      it 'adds an offense when an old type is used with other keywords' do
        expect_offense(<<~RUBY)
        class MyType
          argument :some_arg, #{old_type}, null: true, description: 'My description'
          ^^^^^^^^^^^^^^^^^^^^#{'^' * old_type.length}^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{message}
        end
        RUBY
      end
    end
  end

  it 'does not add an offense for other types in fields' do
    expect_no_offenses(<<~RUBY.strip)
      class MyType
        field :some_field, GraphQL::Types::JSON
      end
    RUBY
  end

  it 'does not add an offense for other types in arguments' do
    expect_no_offenses(<<~RUBY.strip)
      class MyType
        argument :some_arg, GraphQL::Types::JSON
      end
    RUBY
  end

  it 'does not add an offense for uses outside of field or argument' do
    expect_no_offenses(<<~RUBY.strip)
      class MyType
        foo :some_field, GraphQL::ID_TYPE
      end
    RUBY
  end
end
