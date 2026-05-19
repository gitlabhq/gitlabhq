# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/graphql/access_level_enum'

RSpec.describe RuboCop::Cop::Graphql::AccessLevelEnum, feature_category: :api do
  let(:msg) do
    'Do not use `GraphQL::Types::Int` for access level fields. ' \
      'Use a dedicated enum type (e.g., `Types::AccessLevelEnum`) or ' \
      '`Types::AccessLevelType` instead.'
  end

  context 'when using GraphQL::Types::Int for an access level argument' do
    it 'adds an offense for :access_level' do
      expect_offense(<<~RUBY)
        argument :access_level, GraphQL::Types::Int, required: false
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
      RUBY
    end

    it 'adds an offense for :access_level_execute (prefix)' do
      expect_offense(<<~RUBY)
        argument :access_level_execute, GraphQL::Types::Int, required: false
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
      RUBY
    end

    it 'adds an offense for :min_access_level (suffix)' do
      expect_offense(<<~RUBY)
        argument :min_access_level, GraphQL::Types::Int, required: false
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
      RUBY
    end
  end

  context 'when using GraphQL::Types::Int for an access level field' do
    it 'adds an offense for :access_level' do
      expect_offense(<<~RUBY)
        field :access_level, GraphQL::Types::Int, null: true
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
      RUBY
    end

    it 'adds an offense for :access_level_execute (prefix)' do
      expect_offense(<<~RUBY)
        field :access_level_execute, GraphQL::Types::Int, null: true
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
      RUBY
    end

    it 'adds an offense for :push_access_level (suffix)' do
      expect_offense(<<~RUBY)
        field :push_access_level, GraphQL::Types::Int, null: true
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
      RUBY
    end
  end

  context 'when using keyword type syntax' do
    it 'adds an offense for argument with type: keyword' do
      expect_offense(<<~RUBY)
        argument :access_level, type: GraphQL::Types::Int, required: false
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
      RUBY
    end
  end

  context 'when using ::GraphQL prefix (cbase)' do
    it 'adds an offense' do
      expect_offense(<<~RUBY)
        argument :access_level, ::GraphQL::Types::Int, required: false
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
      RUBY
    end
  end

  context 'when not an access level field' do
    it 'does not add an offense' do
      expect_no_offenses(<<~RUBY)
        field :star_count, GraphQL::Types::Int, null: false
      RUBY
    end
  end

  context 'when access_level uses a proper type' do
    it 'does not add an offense' do
      expect_no_offenses(<<~RUBY)
        argument :access_level, Types::AccessLevelEnum, required: false
      RUBY
    end
  end
end
