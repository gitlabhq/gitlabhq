# frozen_string_literal: true

require 'rubocop_spec_helper'

require_relative '../../../../rubocop/cop/graphql/resolver_type'

RSpec.describe RuboCop::Cop::Graphql::ResolverType do
  it 'adds an offense when there is no type annotation' do
    expect_offense(<<~SRC)
      module Resolvers
        class FooResolver < BaseResolver
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Missing type annotation: Please add `type` DSL method call. e.g: type UserType.connection_type, null: true
          def resolve(**args)
            [:thing]
          end
        end
      end
    SRC
  end

  it 'does not add an offense for resolvers that have a type call' do
    expect_no_offenses(<<-SRC)
      module Resolvers
        class FooResolver < BaseResolver
          type [SomeEnum], null: true

          def resolve(**args)
            [:thing]
          end
        end
      end
    SRC
  end

  it 'ignores type calls on other objects' do
    expect_offense(<<~SRC)
      module Resolvers
        class FooResolver < BaseResolver
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Missing type annotation: Please add `type` DSL method call. e.g: type UserType.connection_type, null: true
          class FalsePositive < BaseObject
            type RedHerringType, null: true
          end

          def resolve(**args)
            [:thing]
          end
        end
      end
    SRC
  end

  it 'does not add an offense unless the class is named using the Resolver convention' do
    expect_no_offenses(<<-TYPE)
      module Resolvers
        class FooThingy
          def something_other_than_resolve(**args)
            [:thing]
          end
        end
      end
    TYPE
  end
end
