# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/graphql/descriptions'

RSpec.describe RuboCop::Cop::Graphql::Descriptions do
  context 'with fields' do
    it 'adds an offense when there is no description' do
      expect_offense(<<~TYPE)
        module Types
          class FakeType < BaseObject
            field :a_thing,
            ^^^^^^^^^^^^^^^ #{described_class::MSG_NO_DESCRIPTION}
              GraphQL::Types::String,
              null: false
          end
        end
      TYPE

      expect_no_corrections
    end

    it 'adds an offense when description does not end in a period' do
      expect_offense(<<~TYPE)
        module Types
          class FakeType < BaseObject
            field :a_thing,
            ^^^^^^^^^^^^^^^ #{described_class::MSG_NO_PERIOD}
              GraphQL::Types::String,
              null: false,
              description: 'Description of a thing'
          end
        end
      TYPE
    end

    it 'adds an offense when description begins with "A"' do
      expect_offense(<<~TYPE)
        module Types
          class FakeType < BaseObject
            field :a_thing,
            ^^^^^^^^^^^^^^^ #{described_class::MSG_BAD_START}
              GraphQL::Types::String,
              null: false,
              description: 'A description of the thing.'
          end
        end
      TYPE

      expect_no_corrections
    end

    it 'adds an offense when description begins with "The"' do
      expect_offense(<<~TYPE)
        module Types
          class FakeType < BaseObject
            field :a_thing,
            ^^^^^^^^^^^^^^^ #{described_class::MSG_BAD_START}
              GraphQL::Types::String,
              null: false,
              description: 'The description of the thing.'
          end
        end
      TYPE

      expect_no_corrections
    end

    it 'adds an offense when description contains the demonstrative "this"' do
      expect_offense(<<~TYPE)
        module Types
          class FakeType < BaseObject
            field :a_thing,
            ^^^^^^^^^^^^^^^ #{described_class::MSG_CONTAINS_THIS}
              GraphQL::Types::String,
              null: false,
              description: 'Description of this thing.'
          end
        end
      TYPE

      expect_correction(<<~TYPE)
        module Types
          class FakeType < BaseObject
            field :a_thing,
              GraphQL::Types::String,
              null: false,
              description: 'Description of the thing.'
          end
        end
      TYPE
    end

    it 'does not add an offense when a word does not contain the substring "this"' do
      expect_no_offenses(<<~TYPE)
        module Types
          class FakeType < BaseObject
            field :a_thing,
              GraphQL::Types::String,
              null: false,
              description: 'Description of thistle.'
          end
        end
      TYPE
    end

    it 'does not add an offense when description is correct' do
      expect_no_offenses(<<~TYPE.strip)
        module Types
          class FakeType < BaseObject
            field :a_thing,
              GraphQL::Types::String,
              null: false,
              description: 'Description of a thing.'
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
            ^^^^^^^^^^^^^^^^^^ #{described_class::MSG_NO_DESCRIPTION}
              GraphQL::Types::String,
              null: false
          end
        end
      TYPE

      expect_no_corrections
    end

    it 'adds an offense when description does not end in a period' do
      expect_offense(<<~TYPE)
        module Types
          class FakeType < BaseObject
            argument :a_thing,
            ^^^^^^^^^^^^^^^^^^ #{described_class::MSG_NO_PERIOD}
              GraphQL::Types::String,
              null: false,
              description: 'Behold! A description'
          end
        end
      TYPE
    end

    it 'adds an offense when description begins with "A"' do
      expect_offense(<<~TYPE)
        module Types
          class FakeType < BaseObject
            argument :a_thing,
            ^^^^^^^^^^^^^^^^^^ #{described_class::MSG_BAD_START}
              GraphQL::Types::String,
              null: false,
              description: 'A description.'
          end
        end
      TYPE

      expect_no_corrections
    end

    it 'adds an offense when description begins with "The"' do
      expect_offense(<<~TYPE)
        module Types
          class FakeType < BaseObject
            argument :a_thing,
            ^^^^^^^^^^^^^^^^^^ #{described_class::MSG_BAD_START}
              GraphQL::Types::String,
              null: false,
              description: 'The description.'
          end
        end
      TYPE

      expect_no_corrections
    end

    it 'adds an offense when description contains the demonstrative "this"' do
      expect_offense(<<~TYPE)
        module Types
          class FakeType < BaseObject
            argument :a_thing,
            ^^^^^^^^^^^^^^^^^^ #{described_class::MSG_CONTAINS_THIS}
              GraphQL::Types::String,
              null: false,
              description: 'Description of this thing.'
          end
        end
      TYPE

      expect_correction(<<~TYPE)
        module Types
          class FakeType < BaseObject
            argument :a_thing,
              GraphQL::Types::String,
              null: false,
              description: 'Description of the thing.'
          end
        end
      TYPE
    end

    it 'does not add an offense when a word does not contain the substring "this"' do
      expect_no_offenses(<<~TYPE)
        module Types
          class FakeType < BaseObject
            argument :a_thing,
              GraphQL::Types::String,
              null: false,
              description: 'Description of thistle.'
          end
        end
      TYPE
    end

    it 'does not add an offense when description is correct' do
      expect_no_offenses(<<~TYPE.strip)
        module Types
          class FakeType < BaseObject
            argument :a_thing,
              GraphQL::Types::String,
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
            ^^^^^^^^^^^^^^^^^^^^^^^^^ #{described_class::MSG_NO_DESCRIPTION}
          end
        end
      TYPE

      expect_no_corrections
    end

    it 'adds an offense when description does not end in a period' do
      expect_offense(<<~TYPE)
        module Types
          class FakeEnum < BaseEnum
            value 'FOO', value: 'foo', description: 'bar'
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{described_class::MSG_NO_PERIOD}
          end
        end
      TYPE
    end

    it 'adds an offense when description begins with "The"' do
      expect_offense(<<~TYPE.strip)
        module Types
          class FakeEnum < BaseEnum
            value 'FOO', value: 'foo', description: 'The description.'
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{described_class::MSG_BAD_START}
          end
        end
      TYPE

      expect_no_corrections
    end

    it 'adds an offense when description begins with "A"' do
      expect_offense(<<~TYPE.strip)
        module Types
          class FakeEnum < BaseEnum
            value 'FOO', value: 'foo', description: 'A description.'
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{described_class::MSG_BAD_START}
          end
        end
      TYPE

      expect_no_corrections
    end

    it 'adds an offense when description contains the demonstrative "this"' do
      expect_offense(<<~TYPE.strip)
        module Types
          class FakeEnum < BaseEnum
            value 'FOO', value: 'foo', description: 'Description of this issue.'
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{described_class::MSG_CONTAINS_THIS}
          end
        end
      TYPE

      expect_correction(<<~TYPE.strip)
        module Types
          class FakeEnum < BaseEnum
            value 'FOO', value: 'foo', description: 'Description of the issue.'
          end
        end
      TYPE
    end

    it 'does not add an offense when a word does not contain the substring "this"' do
      expect_no_offenses(<<~TYPE.strip)
        module Types
          class FakeEnum < BaseEnum
            value 'FOO', value: 'foo', description: 'Description of thistle.'
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

  describe 'autocorrecting periods in descriptions' do
    it 'autocorrects missing periods' do
      expect_offense(<<~TYPE)
        module Types
          class FakeType < BaseObject
            field :a_thing,
            ^^^^^^^^^^^^^^^ #{described_class::MSG_NO_PERIOD}
              GraphQL::Types::String,
              null: false,
              description: 'Behold! A description'
          end
        end
      TYPE

      expect_correction(<<~TYPE)
        module Types
          class FakeType < BaseObject
            field :a_thing,
              GraphQL::Types::String,
              null: false,
              description: 'Behold! A description.'
          end
        end
      TYPE
    end

    it 'does not autocorrect if periods exist' do
      expect_no_offenses(<<~TYPE)
        module Types
          class FakeType < BaseObject
            field :a_thing,
              GraphQL::Types::String,
              null: false,
              description: 'Behold! A description.'
          end
        end
      TYPE
    end

    it 'autocorrects a heredoc' do
      expect_offense(<<~TYPE)
        module Types
          class FakeType < BaseObject
            field :a_thing,
            ^^^^^^^^^^^^^^^ #{described_class::MSG_NO_PERIOD}
              GraphQL::Types::String,
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
              GraphQL::Types::String,
              null: false,
              description: <<~DESC
                Behold! A description.
              DESC
          end
        end
      TYPE
    end

    it 'does not autocorrect a heredoc if periods exist' do
      expect_no_offenses(<<~TYPE)
        module Types
          class FakeType < BaseObject
            field :a_thing,
              GraphQL::Types::String,
              null: false,
              description: <<~DESC
                Behold! A description.
              DESC
          end
        end
      TYPE
    end
  end

  describe 'autocorrecting "this" to "the"' do
    it 'autocorrects if "this" is found' do
      expect_offense(<<~TYPE)
          module Types
            class FakeType < BaseObject
              field :a_thing,
              ^^^^^^^^^^^^^^^ #{described_class::MSG_CONTAINS_THIS}
                GraphQL::Types::String,
                null: false,
                description: 'Description of this thing.'
            end
          end
      TYPE

      expect_correction(<<~TYPE)
          module Types
            class FakeType < BaseObject
              field :a_thing,
                GraphQL::Types::String,
                null: false,
                description: 'Description of the thing.'
            end
          end
      TYPE
    end

    it 'does not autocorrect if "this" is not found' do
      expect_no_offenses(<<~TYPE)
          module Types
            class FakeType < BaseObject
              field :a_thing,
                GraphQL::Types::String,
                null: false,
                description: 'Description of the thing.'
            end
          end
      TYPE
    end

    it 'autocorrects a heredoc if "this" is found' do
      expect_offense(<<~TYPE)
          module Types
            class FakeType < BaseObject
              field :a_thing,
              ^^^^^^^^^^^^^^^ #{described_class::MSG_CONTAINS_THIS}
                GraphQL::Types::String,
                null: false,
                description: <<~DESC
                  Description of this thing.
                DESC
            end
          end
      TYPE

      expect_correction(<<~TYPE)
          module Types
            class FakeType < BaseObject
              field :a_thing,
                GraphQL::Types::String,
                null: false,
                description: <<~DESC
                  Description of the thing.
                DESC
            end
          end
      TYPE
    end

    it 'does not autocorrect a heredoc if "this" is not found' do
      expect_no_offenses(<<~TYPE)
          module Types
            class FakeType < BaseObject
              field :a_thing,
                GraphQL::Types::String,
                null: false,
                description: <<~DESC
                  Description of the thing.
                DESC
            end
          end
      TYPE
    end
  end
end
