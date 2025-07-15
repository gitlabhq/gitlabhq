# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/graphql/enum_values'

RSpec.describe RuboCop::Cop::Graphql::EnumValues do
  it 'adds an offense when enum value is not uppercase' do
    expect_offense(<<~RUBY)
      module Types
        class FakeEnum < BaseEnum
          graphql_name 'Fake'

          value 'downcase', description: "Downcase."
                ^^^^^^^^^^ #{described_class::MSG}
        end
      end
    RUBY
  end

  context 'when values are set dynamically' do
    it 'adds an offense when enum value is set without `:upcase`' do
      expect_offense(<<~RUBY)
        VALUES = ['FOO', 'bar']

        module Types
          class FakeEnum < BaseEnum
            graphql_name 'Fake'

            VALUES.each do |val|
              value val, description: "Dynamic value."
                    ^^^ #{described_class::MSG}
            end
          end
        end
      RUBY
    end

    it 'adds no offense when enum value is deprecated' do
      expect_no_offenses(<<~RUBY)
        module Types
          class FakeEnum < BaseEnum
            graphql_name 'Fake'

            value 'foo', deprecated: { reason: 'Use something else' }
          end
        end
      RUBY
    end

    it 'adds no offense when enum value is uppercased literally' do
      expect_no_offenses(<<~'RUBY')
        module Types
          class FakeEnum < BaseEnum
            graphql_name 'Fake'

            value 'FOO'
          end
        end
      RUBY
    end

    it 'adds no offense when enum value is calling upcased' do
      expect_no_offenses(<<~'RUBY')
        VALUES = ['FOO', 'bar']

        module Types
          class FakeEnum < BaseEnum
            graphql_name 'Fake'

            VALUES.each do |val|
              value val.underscore.upcase, description: "Dynamic value."
              value "#{field.upcase.tr(' ', '_')}_ASC"
            end
          end
        end
      RUBY
    end
  end
end
