# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/api/entity_field_type'

RSpec.describe RuboCop::Cop::API::EntityFieldType, :config, feature_category: :api do
  describe 'missing type' do
    it 'registers an offense when documentation has no type' do
      expect_offense(<<~RUBY)
        expose :relation, documentation: { example: 'label' }
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Entity field is missing type declaration. https://docs.gitlab.com/development/api_styleguide#defining-entity-fields.
      RUBY
    end

    it 'registers an offense when there is no documentation hash' do
      expect_offense(<<~RUBY)
        expose :relation, as: :other_name
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Entity field is missing type declaration. https://docs.gitlab.com/development/api_styleguide#defining-entity-fields.
      RUBY
    end
  end

  describe 'invalid type' do
    it 'registers an offense for and corrects symbol type' do
      expect_offense(<<~RUBY)
        expose :relation, documentation: { type: :string, example: 'label' }
                                                 ^^^^^^^ Invalid type for entity field. https://docs.gitlab.com/development/api_styleguide#defining-entity-fields.
      RUBY

      expect_correction(<<~RUBY)
        expose :relation, documentation: { type: 'String', example: 'label' }
      RUBY
    end

    it 'registers an offense for and corrects a lowercase string type' do
      expect_offense(<<~RUBY)
        expose :relation, documentation: { type: 'string', example: 'label' }
                                                 ^^^^^^^^ Invalid type for entity field. https://docs.gitlab.com/development/api_styleguide#defining-entity-fields.
      RUBY
    end

    it 'registers an offense for and corrects a primitive constant type' do
      expect_offense(<<~RUBY)
        expose :relation, documentation: { type: String, example: 'label' }
                                                 ^^^^^^ Invalid type for entity field. https://docs.gitlab.com/development/api_styleguide#defining-entity-fields.
      RUBY

      expect_correction(<<~RUBY)
        expose :relation, documentation: { type: 'String', example: 'label' }
      RUBY
    end

    it 'registers an offense for and corrects a API::Entities constant type' do
      expect_offense(<<~RUBY)
        expose :relation, documentation: { type: API::Entities::SomeEntity, example: 'label' }
                                                 ^^^^^^^^^^^^^^^^^^^^^^^^^ Invalid type for entity field. https://docs.gitlab.com/development/api_styleguide#defining-entity-fields.
      RUBY

      expect_correction(<<~RUBY)
        expose :relation, documentation: { type: 'API::Entities::SomeEntity', example: 'label' }
      RUBY
    end

    it 'registers an offense for but does not correct an unknown class string' do
      expect_offense(<<~RUBY)
        expose :relation, documentation: { type: 'UnknownClass', example: 'label' }
                                                 ^^^^^^^^^^^^^^ Invalid type for entity field. https://docs.gitlab.com/development/api_styleguide#defining-entity-fields.
      RUBY

      expect_no_corrections
    end

    it 'registers an offense for but does not correct an unknown constant' do
      expect_offense(<<~RUBY)
        expose :relation, documentation: { type: UnknownClass, example: 'label' }
                                                 ^^^^^^^^^^^^ Invalid type for entity field. https://docs.gitlab.com/development/api_styleguide#defining-entity-fields.
      RUBY

      expect_no_corrections
    end

    it 'registers an offense but does not correct an unknown symbol' do
      expect_offense(<<~RUBY)
        expose :relation, documentation: { type: :full, example: 'label' }
                                                 ^^^^^ Invalid type for entity field. https://docs.gitlab.com/development/api_styleguide#defining-entity-fields.
      RUBY

      expect_no_corrections
    end

    it 'registers an offense for but does not correct an unknown string' do
      expect_offense(<<~RUBY)
        expose :relation, documentation: { type: 'full', example: 'label' }
                                                 ^^^^^^ Invalid type for entity field. https://docs.gitlab.com/development/api_styleguide#defining-entity-fields.
      RUBY

      expect_no_corrections
    end

    it 'registers an offense for but does not correct an array type' do
      expect_offense(<<~RUBY)
        expose :relation, documentation: { type: ['String'], example: 'label' }
                                                 ^^^^^^^^^^ Invalid type for entity field. https://docs.gitlab.com/development/api_styleguide#defining-entity-fields.
      RUBY

      expect_no_corrections
    end
  end

  describe 'valid type' do
    it 'does not register an offense for String as string' do
      expect_no_offenses(<<~RUBY)
        expose :relation, documentation: { type: 'String', example: 'label' }
      RUBY
    end

    it 'does not register an offense for Integer as string' do
      expect_no_offenses(<<~RUBY)
        expose :relation, documentation: { type: 'Integer', example: 1 }
      RUBY
    end

    it 'does not register an offense for Boolean as string' do
      expect_no_offenses(<<~RUBY)
        expose :relation, documentation: { type: 'Boolean', example: true }
      RUBY
    end

    it 'does not register an offense for Hash as string' do
      expect_no_offenses(<<~RUBY)
        expose :relation, documentation: { type: 'Hash', example: {} }
      RUBY
    end

    it 'does not register an offense for Array as string' do
      expect_no_offenses(<<~RUBY)
        expose :relation, documentation: { type: 'Array', example: [] }
      RUBY
    end

    it 'does not register an offense for JSON as string' do
      expect_no_offenses(<<~RUBY)
        expose :relation, documentation: { type: 'JSON', example: {} }
      RUBY
    end

    it 'does not register an offense for API::Entities string reference' do
      expect_no_offenses(<<~RUBY)
        expose :relation, documentation: { type: 'API::Entities::SomeType', example: 'label' }
      RUBY
    end

    it 'does not register an offense for API::Entities string reference with leading colons' do
      expect_no_offenses(<<~RUBY)
        expose :relation, documentation: { type: '::API::Entities::SomeType', example: 'label' }
      RUBY
    end
  end

  describe 'using option' do
    it 'does not register an offense when using is a constant' do
      expect_no_offenses(<<~RUBY)
        expose :group, using: API::Entities::BasicGroupDetails
      RUBY
    end

    it 'does not register an offense when using is a constant with leading colons' do
      expect_no_offenses(<<~RUBY)
        expose :group, using: ::API::Entities::BasicGroupDetails
      RUBY
    end

    it 'registers an offense when using is a string' do
      expect_offense(<<~RUBY)
        expose :group, using: 'API::Entities::BasicGroupDetails'
                              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Invalid type for entity field. https://docs.gitlab.com/development/api_styleguide#defining-entity-fields.
      RUBY

      expect_correction(<<~RUBY)
        expose :group, using: API::Entities::BasicGroupDetails
      RUBY
    end

    it 'registers an offense when using is not an API::Entities reference' do
      expect_offense(<<~RUBY)
        expose :group, using: SomeOtherClass
                              ^^^^^^^^^^^^^^ Invalid type for entity field. https://docs.gitlab.com/development/api_styleguide#defining-entity-fields.
      RUBY

      expect_no_corrections
    end

    it 'registers an offense when using is a string not starting with API::Entities' do
      expect_offense(<<~RUBY)
        expose :group, using: 'SomeOtherClass'
                              ^^^^^^^^^^^^^^^^ Invalid type for entity field. https://docs.gitlab.com/development/api_styleguide#defining-entity-fields.
      RUBY

      expect_no_corrections
    end

    it 'registers an offense when using is a symbol' do
      expect_offense(<<~RUBY)
        expose :group, using: :some_type
                              ^^^^^^^^^^ Invalid type for entity field. https://docs.gitlab.com/development/api_styleguide#defining-entity-fields.
      RUBY

      expect_no_corrections
    end
  end
end
