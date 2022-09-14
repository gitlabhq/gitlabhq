# frozen_string_literal: true

require 'rubocop_spec_helper'

require_relative '../../../../rubocop/cop/graphql/graphql_name_position'

RSpec.describe RuboCop::Cop::Graphql::GraphqlNamePosition do
  it 'adds an offense when graphql_name is not on the first line' do
    expect_offense(<<~TYPE)
      module Types
        class AType < BaseObject
        ^^^^^^^^^^^^^^^^^^^^^^^^ `graphql_name` should be the first line of the class: https://docs.gitlab.com/ee/development/api_graphql_styleguide.html#naming-conventions
          field :a_thing
          field :another_thing
          graphql_name 'ATypeName'
        end
      end
    TYPE
  end

  it 'does not add an offense for classes that have no call to graphql_name' do
    expect_no_offenses(<<~TYPE.strip)
      module Types
        class AType < BaseObject
          authorize :an_ability, :second_ability

          field :a_thing
        end
      end
    TYPE
  end

  it 'does not add an offense for classes that only call graphql_name' do
    expect_no_offenses(<<~TYPE.strip)
      module Types
        class AType < BaseObject
          graphql_name 'ATypeName'
        end
      end
    TYPE
  end
end
