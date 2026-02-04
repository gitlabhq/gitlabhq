# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/api/deprecated_in_description'

RSpec.describe RuboCop::Cop::API::DeprecatedInDescription, :config, feature_category: :api do
  context 'when desc block contains DEPRECATED in description' do
    it 'registers an offense and corrects with brackets' do
      expect_offense(<<~RUBY)
        desc "[DEPRECATED] Update a user's credit_card_validation" do
             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not use DEPRECATED in API description. Use `deprecated true` inside the desc block instead. https://docs.gitlab.com/development/api_styleguide/#marking-endpoints-as-deprecated
          success Entities::UserCreditCardValidations
          tags ['users']
        end
      RUBY

      expect_correction(<<~RUBY)
        desc "Update a user's credit_card_validation" do
          success Entities::UserCreditCardValidations
          tags ['users']
          deprecated true
        end
      RUBY
    end

    it 'registers an offense and corrects without brackets' do
      expect_offense(<<~RUBY)
        desc "DEPRECATED Update a user's credit_card_validation" do
             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not use DEPRECATED in API description. Use `deprecated true` inside the desc block instead. https://docs.gitlab.com/development/api_styleguide/#marking-endpoints-as-deprecated
          success Entities::UserCreditCardValidations
          tags ['users']
        end
      RUBY

      expect_correction(<<~RUBY)
        desc "Update a user's credit_card_validation" do
          success Entities::UserCreditCardValidations
          tags ['users']
          deprecated true
        end
      RUBY
    end

    it 'registers an offense and corrects with lowercase deprecated' do
      expect_offense(<<~RUBY)
        desc "[deprecated] Get user info" do
             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not use DEPRECATED in API description. Use `deprecated true` inside the desc block instead. https://docs.gitlab.com/development/api_styleguide/#marking-endpoints-as-deprecated
          success Entities::User
        end
      RUBY

      expect_correction(<<~RUBY)
        desc "Get user info" do
          success Entities::User
          deprecated true
        end
      RUBY
    end

    it 'does not add duplicate deprecated true when already present' do
      expect_offense(<<~RUBY)
        desc "[DEPRECATED] Update user" do
             ^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not use DEPRECATED in API description. Use `deprecated true` inside the desc block instead. https://docs.gitlab.com/development/api_styleguide/#marking-endpoints-as-deprecated
          success Entities::User
          deprecated true
        end
      RUBY

      expect_correction(<<~RUBY)
        desc "Update user" do
          success Entities::User
          deprecated true
        end
      RUBY
    end

    it 'handles single quotes' do
      expect_offense(<<~RUBY)
        desc '[DEPRECATED] Update user' do
             ^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not use DEPRECATED in API description. Use `deprecated true` inside the desc block instead. https://docs.gitlab.com/development/api_styleguide/#marking-endpoints-as-deprecated
          success Entities::User
        end
      RUBY

      expect_correction(<<~RUBY)
        desc 'Update user' do
          success Entities::User
          deprecated true
        end
      RUBY
    end
  end

  context 'when desc block does not contain DEPRECATED' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        desc "Update a user's credit_card_validation" do
          success Entities::UserCreditCardValidations
          tags ['users']
        end
      RUBY
    end

    it 'does not register an offense when using deprecated true' do
      expect_no_offenses(<<~RUBY)
        desc "Update a user's credit_card_validation" do
          success Entities::UserCreditCardValidations
          tags ['users']
          deprecated true
        end
      RUBY
    end
  end

  context 'when desc is called without a block' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        desc '[DEPRECATED] Simple description without block'
      RUBY
    end
  end

  context 'when desc is called on an object' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        object.desc '[DEPRECATED] Method call on object' do
          success Entities::Something
        end
      RUBY
    end
  end
end
