# frozen_string_literal: true

require 'rubocop_spec_helper'

require_relative '../../../../rubocop/cop/graphql/authorize_types'

RSpec.describe RuboCop::Cop::Graphql::AuthorizeTypes do
  it 'adds an offense when there is no authorize call' do
    expect_offense(<<~TYPE)
      module Types
        class AType < BaseObject
        ^^^^^^^^^^^^^^^^^^^^^^^^ Add an `authorize :ability` call to the type: https://docs.gitlab.com/ee/development/graphql_guide/authorization.html#type-authorization
          field :a_thing
          field :another_thing
        end
      end
    TYPE
  end

  it 'adds add an offense when authorize has no arguments' do
    expect_offense(<<~TYPE.strip)
      module Types
        class AType < SuperClassWithFields
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Add an `authorize :ability` call to the type: https://docs.gitlab.com/ee/development/graphql_guide/authorization.html#type-authorization
          authorize
        end
      end
    TYPE
  end

  it 'adds add an offense when authorize is empty' do
    expect_offense(<<~TYPE.strip)
      module Types
        class AType < SuperClassWithFields
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Add an `authorize :ability` call to the type: https://docs.gitlab.com/ee/development/graphql_guide/authorization.html#type-authorization
          authorize []
        end
      end
    TYPE
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

  it 'does not add an offense for subtypes of BaseUnion' do
    expect_no_offenses(<<~TYPE)
      module Types
        class AType < BaseUnion
          possible_types Types::Foo, Types::Bar
        end
      end
    TYPE
  end

  it 'does not add an offense for subtypes of BaseInputObject' do
    expect_no_offenses(<<~TYPE)
      module Types
        class AType < BaseInputObject
          argument :a_thing
        end
      end
    TYPE
  end

  it 'does not add an offense for InputTypes' do
    expect_no_offenses(<<~TYPE)
      module Types
        class AInputType < SomeObjectType
          argument :a_thing
        end
      end
    TYPE
  end
end
