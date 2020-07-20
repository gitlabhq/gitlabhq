# frozen_string_literal: true

require 'fast_spec_helper'
require 'rubocop'
require_relative '../../../../rubocop/cop/api/grape_array_missing_coerce'

RSpec.describe RuboCop::Cop::API::GrapeArrayMissingCoerce do
  include CopHelper

  subject(:cop) { described_class.new }

  it 'adds an offense with a required parameter' do
    inspect_source(<<~CODE)
      class SomeAPI < Grape::API::Instance
        params do
          requires :values, type: Array[String]
        end
      end
    CODE

    expect(cop.offenses.size).to eq(1)
  end

  it 'adds an offense with an optional parameter' do
    inspect_source(<<~CODE)
      class SomeAPI < Grape::API::Instance
        params do
          optional :values, type: Array[String]
        end
      end
    CODE

    expect(cop.offenses.size).to eq(1)
  end

  it 'does not add an offense' do
    inspect_source(<<~CODE)
      class SomeAPI < Grape::API::Instance
        params do
          requires :values, type: Array[String], coerce_with: ->(val) { val.split(',').map(&:strip) }
          requires :milestone, type: String, desc: 'Milestone title'
          optional :assignee_id, types: [Integer, String], integer_none_any: true,
            desc: 'Return issues which are assigned to the user with the given ID'
        end
      end
    CODE

    expect(cop.offenses.size).to be_zero
  end

  it 'does not add an offense for unrelated classes' do
    inspect_source(<<~CODE)
      class SomeClass
        params do
          requires :values, type: Array[String]
        end
      end
    CODE

    expect(cop.offenses.size).to be_zero
  end
end
