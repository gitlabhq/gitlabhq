# frozen_string_literal: true

require 'fast_spec_helper'
require 'rubocop'
require_relative '../../../../rubocop/cop/graphql/descriptions'

RSpec.describe RuboCop::Cop::Graphql::Descriptions, type: :rubocop do
  include CopHelper

  subject(:cop) { described_class.new }

  context 'fields' do
    it 'adds an offense when there is no field description' do
      inspect_source(<<~TYPE)
        module Types
          class FakeType < BaseObject
            field :a_thing,
              GraphQL::STRING_TYPE,
              null: false
          end
        end
      TYPE

      expect(cop.offenses.size).to eq 1
    end

    it 'does not add an offense for fields with a description' do
      expect_no_offenses(<<~TYPE.strip)
        module Types
          class FakeType < BaseObject
            graphql_name 'FakeTypeName'

            argument :a_thing,
              GraphQL::STRING_TYPE,
              null: false,
              description: 'A descriptive description'
          end
        end
      TYPE
    end
  end

  context 'arguments' do
    it 'adds an offense when there is no argument description' do
      inspect_source(<<~TYPE)
        module Types
          class FakeType < BaseObject
            argument :a_thing,
              GraphQL::STRING_TYPE,
              null: false
          end
        end
      TYPE

      expect(cop.offenses.size).to eq 1
    end

    it 'does not add an offense for arguments with a description' do
      expect_no_offenses(<<~TYPE.strip)
        module Types
          class FakeType < BaseObject
            graphql_name 'FakeTypeName'

            argument :a_thing,
              GraphQL::STRING_TYPE,
              null: false,
              description: 'Behold! A description'
          end
        end
      TYPE
    end
  end
end
