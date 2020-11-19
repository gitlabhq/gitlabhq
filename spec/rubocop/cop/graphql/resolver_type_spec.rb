# frozen_string_literal: true

require 'fast_spec_helper'
require 'rubocop'

require_relative '../../../../rubocop/cop/graphql/resolver_type'

RSpec.describe RuboCop::Cop::Graphql::ResolverType, type: :rubocop do
  include CopHelper

  subject(:cop) { described_class.new }

  it 'adds an offense when there is no type annotaion' do
    lacks_type = <<-SRC
      module Resolvers
        class FooResolver < BaseResolver
          def resolve(**args)
            [:thing]
          end
        end
      end
    SRC

    inspect_source(lacks_type)

    expect(cop.offenses.size).to eq 1
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
    lacks_type = <<-SRC
      module Resolvers
        class FooResolver < BaseResolver
          class FalsePositive < BaseObject
            type RedHerringType, null: true
          end

          def resolve(**args)
            [:thing]
          end
        end
      end
    SRC

    inspect_source(lacks_type)

    expect(cop.offenses.size).to eq 1
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
