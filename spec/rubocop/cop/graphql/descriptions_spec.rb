# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../../rubocop/cop/graphql/descriptions'

RSpec.describe RuboCop::Cop::Graphql::Descriptions do
  subject(:cop) { described_class.new }

  context 'with fields' do
    it 'adds an offense when there is no description' do
      expect_offense(<<~TYPE)
        module Types
          class FakeType < BaseObject
            field :a_thing,
            ^^^^^^^^^^^^^^^ Please add a `description` property.
              GraphQL::STRING_TYPE,
              null: false
          end
        end
      TYPE
    end

    it 'adds an offense when description does not end in a period' do
      expect_offense(<<~TYPE)
        module Types
          class FakeType < BaseObject
            field :a_thing,
            ^^^^^^^^^^^^^^^ `description` strings must end with a `.`.
              GraphQL::STRING_TYPE,
              null: false,
              description: 'A descriptive description'
          end
        end
      TYPE
    end

    it 'does not add an offense when description is correct' do
      expect_no_offenses(<<~TYPE.strip)
        module Types
          class FakeType < BaseObject
            field :a_thing,
              GraphQL::STRING_TYPE,
              null: false,
              description: 'A descriptive description.'
          end
        end
      TYPE
    end

    it 'does not add an offense when there is a resolver' do
      expect_no_offenses(<<~TYPE.strip)
        module Types
          class FakeType < BaseObject
            field :a_thing, resolver: ThingResolver
          end
        end
      TYPE
    end
  end

  context 'with arguments' do
    it 'adds an offense when there is no description' do
      expect_offense(<<~TYPE)
        module Types
          class FakeType < BaseObject
            argument :a_thing,
            ^^^^^^^^^^^^^^^^^^ Please add a `description` property.
              GraphQL::STRING_TYPE,
              null: false
          end
        end
      TYPE
    end

    it 'adds an offense when description does not end in a period' do
      expect_offense(<<~TYPE)
        module Types
          class FakeType < BaseObject
            argument :a_thing,
            ^^^^^^^^^^^^^^^^^^ `description` strings must end with a `.`.
              GraphQL::STRING_TYPE,
              null: false,
              description: 'Behold! A description'
          end
        end
      TYPE
    end

    it 'does not add an offense when description is correct' do
      expect_no_offenses(<<~TYPE.strip)
        module Types
          class FakeType < BaseObject
            argument :a_thing,
              GraphQL::STRING_TYPE,
              null: false,
              description: 'Behold! A description.'
          end
        end
      TYPE
    end
  end

  context 'with enum values' do
    it 'adds an offense when there is no description' do
      expect_offense(<<~TYPE)
        module Types
          class FakeEnum < BaseEnum
            value 'FOO', value: 'foo'
            ^^^^^^^^^^^^^^^^^^^^^^^^^ Please add a `description` property.
          end
        end
      TYPE
    end

    it 'adds an offense when description does not end in a period' do
      expect_offense(<<~TYPE)
        module Types
          class FakeEnum < BaseEnum
            value 'FOO', value: 'foo', description: 'bar'
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `description` strings must end with a `.`.
          end
        end
      TYPE
    end

    it 'does not add an offense when description is correct (defined using `description:`)' do
      expect_no_offenses(<<~TYPE.strip)
        module Types
          class FakeEnum < BaseEnum
            value 'FOO', value: 'foo', description: 'bar.'
          end
        end
      TYPE
    end

    it 'does not add an offense when description is correct (defined as a second argument)' do
      expect_no_offenses(<<~TYPE.strip)
        module Types
          class FakeEnum < BaseEnum
            value 'FOO', 'bar.', value: 'foo'
          end
        end
      TYPE
    end
  end

  describe 'autocorrecting descriptions without periods' do
    it 'can autocorrect' do
      expect_offense(<<~TYPE)
        module Types
          class FakeType < BaseObject
            field :a_thing,
            ^^^^^^^^^^^^^^^ `description` strings must end with a `.`.
              GraphQL::STRING_TYPE,
              null: false,
              description: 'Behold! A description'
          end
        end
      TYPE

      expect_correction(<<~TYPE)
        module Types
          class FakeType < BaseObject
            field :a_thing,
              GraphQL::STRING_TYPE,
              null: false,
              description: 'Behold! A description.'
          end
        end
      TYPE
    end

    it 'can autocorrect a heredoc' do
      expect_offense(<<~TYPE)
        module Types
          class FakeType < BaseObject
            field :a_thing,
            ^^^^^^^^^^^^^^^ `description` strings must end with a `.`.
              GraphQL::STRING_TYPE,
              null: false,
              description: <<~DESC
                Behold! A description
              DESC
          end
        end
      TYPE

      expect_correction(<<~TYPE)
        module Types
          class FakeType < BaseObject
            field :a_thing,
              GraphQL::STRING_TYPE,
              null: false,
              description: <<~DESC
                Behold! A description.
              DESC
          end
        end
      TYPE
    end
  end
end
