# frozen_string_literal: true

require 'fast_spec_helper'
require 'rubocop'
require_relative '../../../../rubocop/cop/graphql/json_type'

RSpec.describe RuboCop::Cop::Graphql::JSONType, type: :rubocop do
  include CopHelper

  subject(:cop) { described_class.new }

  context 'fields' do
    it 'adds an offense when GraphQL::Types::JSON is used' do
      inspect_source(<<~RUBY.strip)
        class MyType
          field :some_field, GraphQL::Types::JSON
        end
      RUBY

      expect(cop.offenses.size).to eq(1)
    end

    it 'adds an offense when GraphQL::Types::JSON is used with other keywords' do
      inspect_source(<<~RUBY.strip)
        class MyType
          field :some_field, GraphQL::Types::JSON, null: true, description: 'My description'
        end
      RUBY

      expect(cop.offenses.size).to eq(1)
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
      inspect_source(<<~RUBY.strip)
        class MyType
          argument :some_arg, GraphQL::Types::JSON
        end
      RUBY

      expect(cop.offenses.size).to eq(1)
    end

    it 'adds an offense when GraphQL::Types::JSON is used with other keywords' do
      inspect_source(<<~RUBY.strip)
        class MyType
          argument :some_arg, GraphQL::Types::JSON, null: true, description: 'My description'
        end
      RUBY

      expect(cop.offenses.size).to eq(1)
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
