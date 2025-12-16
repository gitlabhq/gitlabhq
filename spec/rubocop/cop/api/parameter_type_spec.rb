# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/api/parameter_type'

RSpec.describe RuboCop::Cop::API::ParameterType, :config, feature_category: :api do
  describe 'valid type declarations' do
    it 'does not register an offense for String type' do
      expect_no_offenses(<<~RUBY)
        params do
          requires :name, type: String, desc: 'Name'
        end
      RUBY
    end

    it 'does not register an offense for Integer type' do
      expect_no_offenses(<<~RUBY)
        params do
          requires :id, type: Integer, desc: 'ID'
        end
      RUBY
    end

    it 'does not register an offense for Hash type' do
      expect_no_offenses(<<~RUBY)
        params do
          requires :data, type: Hash, desc: 'Data'
        end
      RUBY
    end

    it 'does not register an offense for Array type' do
      expect_no_offenses(<<~RUBY)
        params do
          requires :items, type: Array, desc: 'Items'
        end
      RUBY
    end

    it 'does not register an offense for Array with type parameter' do
      expect_no_offenses(<<~RUBY)
        params do
          requires :items, type: Array[String], desc: 'Items'
        end
      RUBY
    end

    it 'does not register an offense for Boolean type' do
      expect_no_offenses(<<~RUBY)
        params do
          requires :flag, type: Boolean, desc: 'Flag'
        end
      RUBY
    end

    it 'does not register an offense for multiple types' do
      expect_no_offenses(<<~RUBY)
        params do
          requires :id, types: [String, Integer], desc: 'ID'
        end
      RUBY
    end

    it 'does not register an offense for nested Hash params' do
      expect_no_offenses(<<~RUBY)
        params do
          requires :current_file, type: Hash, desc: "File information" do
            requires :file_name, type: String, limit: 255, desc: 'File name'
            requires :content, type: String, desc: 'Content'
            optional :metadata, type: Array[String], desc: 'Metadata'
          end
        end
      RUBY
    end

    it 'does not register an offense for custom ::API::Validations::Types' do
      expect_no_offenses(<<~RUBY)
        params do
          requires :value, type: ::API::Validations::Types::CustomType, desc: 'Custom'
        end
      RUBY
    end

    it 'does not register an offense for optional params with valid types' do
      expect_no_offenses(<<~RUBY)
        params do
          optional :search, type: String, desc: 'Search query'
        end
      RUBY
    end

    it 'does not register an offense for params with coerce_with' do
      expect_no_offenses(<<~RUBY)
        params do
          requires :value, type: CustomType, coerce_with: CustomCoercer, desc: 'Value'
        end
      RUBY
    end
  end

  describe 'hidden params' do
    it 'does not register an offense for hidden params without type' do
      expect_no_offenses(<<~RUBY)
        params do
          requires :invisible, documentation: { hidden: true }, desc: 'Hidden'
        end
      RUBY
    end

    it 'does not register an offense for hidden params with invalid type' do
      expect_no_offenses(<<~RUBY)
        params do
          requires :invisible, type: :string, documentation: { hidden: true }, desc: 'Hidden'
        end
      RUBY
    end
  end

  describe 'invalid type declarations' do
    it 'registers an offense for symbol type' do
      expect_offense(<<~RUBY)
        params do
          requires :name, type: :string, desc: 'Name'
                                ^^^^^^^ Invalid type or types. API params types must be one of Grape supported param types. https://docs.gitlab.com/development/api_styleguide#methods-and-parameters-description.
        end
      RUBY
    end

    it 'registers an offense for string type' do
      expect_offense(<<~RUBY)
        params do
          requires :name, type: "string", desc: 'Name'
                                ^^^^^^^^ Invalid type or types. API params types must be one of Grape supported param types. https://docs.gitlab.com/development/api_styleguide#methods-and-parameters-description.
        end
      RUBY
    end

    it 'registers an offense for symbol types in array' do
      expect_offense(<<~RUBY)
        params do
          requires :id, types: [:string, :integer], desc: 'ID'
                                         ^^^^^^^^ Invalid type or types. API params types must be one of Grape supported param types. https://docs.gitlab.com/development/api_styleguide#methods-and-parameters-description.
                                ^^^^^^^ Invalid type or types. API params types must be one of Grape supported param types. https://docs.gitlab.com/development/api_styleguide#methods-and-parameters-description.
        end
      RUBY
    end

    it 'registers an offense for string types in array' do
      expect_offense(<<~RUBY)
        params do
          requires :id, types: ["string", "integer"], desc: 'ID'
                                          ^^^^^^^^^ Invalid type or types. API params types must be one of Grape supported param types. https://docs.gitlab.com/development/api_styleguide#methods-and-parameters-description.
                                ^^^^^^^^ Invalid type or types. API params types must be one of Grape supported param types. https://docs.gitlab.com/development/api_styleguide#methods-and-parameters-description.
        end
      RUBY
    end

    it 'registers an offense for invalid type in Array parameter' do
      expect_offense(<<~RUBY)
        params do
          requires :items, type: Array[:string], desc: 'Items'
                                       ^^^^^^^ Invalid type or types. API params types must be one of Grape supported param types. https://docs.gitlab.com/development/api_styleguide#methods-and-parameters-description.
        end
      RUBY
    end

    it 'registers an offense for undefined constant type' do
      expect_offense(<<~RUBY)
        params do
          requires :value, type: UndefinedType, desc: 'Value'
                                 ^^^^^^^^^^^^^ Invalid type or types. API params types must be one of Grape supported param types. https://docs.gitlab.com/development/api_styleguide#methods-and-parameters-description.
        end
      RUBY
    end

    it 'registers an offense for bare method call in Array parameter' do
      expect_offense(<<~RUBY)
        params do
          requires :items, type: Array[undefined_method], desc: 'Items'
                                       ^^^^^^^^^^^^^^^^ Invalid type or types. API params types must be one of Grape supported param types. https://docs.gitlab.com/development/api_styleguide#methods-and-parameters-description.
        end
      RUBY
    end

    it 'registers an offense when both type and types are specified' do
      expect_offense(<<~RUBY)
        params do
          optional :param, type: String, types: [String, Integer]
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Duplicate type definitions. API params must only define one of type or types.
        end
      RUBY
    end
  end

  describe 'missing type declarations' do
    it 'registers an offense for requires without type' do
      expect_offense(<<~RUBY)
        params do
          requires :name, desc: 'Name'
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ API parameter is missing type declaration.
        end
      RUBY
    end

    it 'registers an offense for optional without type' do
      expect_offense(<<~RUBY)
        params do
          optional :search, desc: 'Search'
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ API parameter is missing type declaration.
        end
      RUBY
    end

    it 'registers an offense for nested params without type' do
      expect_offense(<<~RUBY)
        params do
          requires :current_file, type: Hash, desc: "File information" do
            requires :file_name, desc: 'File name'
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ API parameter is missing type declaration.
          end
        end
      RUBY
    end
  end
end
