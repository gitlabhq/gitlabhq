# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/api/grape_array_missing_coerce'

RSpec.describe RuboCop::Cop::API::GrapeArrayMissingCoerce do
  let(:msg) do
    "This Grape parameter defines an Array but is missing a coerce_with definition. " \
    "For more details, see " \
    "https://github.com/ruby-grape/grape/blob/master/UPGRADING.md#ensure-that-array-types-have-explicit-coercions"
  end

  it 'adds an offense with a required parameter' do
    expect_offense(<<~TYPE)
      class SomeAPI < Grape::API::Instance
        params do
          requires :values, type: Array[String]
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
        end
      end
    TYPE
  end

  it 'adds an offense with an optional parameter' do
    expect_offense(<<~TYPE)
      class SomeAPI < Grape::API::Instance
        params do
          optional :values, type: Array[String]
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
        end
      end
    TYPE
  end

  it 'does not add an offense' do
    expect_no_offenses(<<~CODE)
      class SomeAPI < Grape::API::Instance
        params do
          requires :values, type: Array[String], coerce_with: ->(val) { val.split(',').map(&:strip) }
          requires :milestone, type: String, desc: 'Milestone title'
          optional :assignee_id, types: [Integer, String], integer_none_any: true,
            desc: 'Return issues which are assigned to the user with the given ID'
        end
      end
    CODE
  end

  it 'does not add an offense for unrelated classes' do
    expect_no_offenses(<<~CODE)
      class SomeClass
        params do
          requires :values, type: Array[String]
        end
      end
    CODE
  end
end
