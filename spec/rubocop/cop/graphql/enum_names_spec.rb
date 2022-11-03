# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/graphql/enum_names'

RSpec.describe RuboCop::Cop::Graphql::EnumNames do
  describe 'class name' do
    it 'adds an offense when class name does not end with `Enum`' do
      expect_offense(<<~ENUM)
        module Types
          class Fake < BaseEnum
                ^^^^ #{described_class::CLASS_NAME_SUFFIX_MSG}
            graphql_name 'Fake'
          end
        end
      ENUM
    end
  end

  describe 'graphql_name' do
    it 'adds an offense when `graphql_name` is not set' do
      expect_offense(<<~ENUM)
        module Types
          class FakeEnum < BaseEnum
          ^^^^^^^^^^^^^^^^^^^^^^^^^ #{described_class::GRAPHQL_NAME_MISSING_MSG}
          end
        end
      ENUM
    end

    it 'adds no offense when `declarative_enum` is used' do
      expect_no_offenses(<<~ENUM)
        module Types
          class FakeEnum < BaseEnum
            declarative_enum ::FakeModule::FakeDeclarativeEnum
          end
        end
      ENUM
    end

    it 'adds an offense when `graphql_name` includes `enum`' do
      expect_offense(<<~ENUM)
        module Types
          class FakeEnum < BaseEnum
            graphql_name 'FakeEnum'
                         ^^^^^^^^^^ #{described_class::GRAPHQL_NAME_WITH_ENUM_MSG}
          end
        end
      ENUM
    end
  end
end
