# frozen_string_literal: true

require 'fast_spec_helper'
require 'rubocop'
require 'rubocop/rspec/support'
require_relative '../../../../rubocop/cop/graphql/authorize_types'

describe RuboCop::Cop::Graphql::AuthorizeTypes do
  include RuboCop::RSpec::ExpectOffense
  include CopHelper

  subject(:cop) { described_class.new }

  context 'when NOT in a type folder' do
    before do
      allow(cop).to receive(:in_type?).and_return(false)
    end

    it 'does not add an offense even though there is no authorize call' do
      expect_no_offenses(<<~TYPE.strip)
        module Types
          class AType < BaseObject
            field :a_thing
            field :another_thing
          end
        end
      TYPE
    end
  end

  context 'when in a type folder' do
    before do
      allow(cop).to receive(:in_type?).and_return(true)
    end

    it 'adds an offense when there is no authorize call' do
      inspect_source(<<~TYPE)
        module Types
          class AType < BaseObject
            field :a_thing
            field :another_thing
          end
        end
      TYPE

      expect(cop.offenses.size).to eq 1
    end

    it 'does not add an offense for classes that have an authorize call' do
      expect_no_offenses(<<~TYPE.strip)
        module Types
          class AType < BaseObject
            graphql_name 'ATypeName'

            authorize :an_ability, :second_ability

            field :a_thing
          end
        end
      TYPE
    end

    it 'does not add an offense for classes that only have an authorize call' do
      expect_no_offenses(<<~TYPE.strip)
        module Types
          class AType < SuperClassWithFields
            authorize :an_ability
          end
        end
      TYPE
    end

    it 'does not add an offense for base types' do
      expect_no_offenses(<<~TYPE)
        module Types
          class AType < BaseEnum
            field :a_thing
          end
        end
      TYPE
    end

    it 'does not add an offense for Enums' do
      expect_no_offenses(<<~TYPE)
        module Types
          class ATypeEnum < AnotherEnum
            field :a_thing
          end
        end
      TYPE
    end
  end
end
