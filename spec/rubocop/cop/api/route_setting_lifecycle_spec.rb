# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/api/route_setting_lifecycle'

RSpec.describe RuboCop::Cop::API::RouteSettingLifecycle, :config, feature_category: :api do
  context 'with valid lifecycle values' do
    it 'does not register an offense for :beta' do
      expect_no_offenses(<<~RUBY)
        route_setting :lifecycle, :beta
      RUBY
    end

    it 'does not register an offense for :experiment' do
      expect_no_offenses(<<~RUBY)
        route_setting :lifecycle, :experiment
      RUBY
    end

    it 'does not register an offense inside a namespace block' do
      expect_no_offenses(<<~RUBY)
        namespace :users do
          route_setting :lifecycle, :beta
          get ':id' do
          end
        end
      RUBY
    end

    it 'does not register an offense inside a resource block' do
      expect_no_offenses(<<~RUBY)
        resources :projects do
          route_setting :lifecycle, :experiment
        end
      RUBY
    end
  end

  context 'with invalid lifecycle values' do
    it 'registers an offense for invalid symbol' do
      expect_offense(<<~RUBY)
        route_setting :lifecycle, :alpha
                                  ^^^^^^ Invalid lifecycle value `:alpha`. Use one of: :beta, :experiment. Omit route_setting :lifecycle for generally available endpoints. See https://docs.gitlab.com/policy/development_stages_support/
      RUBY
    end

    it 'registers an offense for string instead of symbol' do
      expect_offense(<<~RUBY)
        route_setting :lifecycle, 'beta'
                                  ^^^^^^ Invalid lifecycle value `'beta'`. Use one of: :beta, :experiment. Omit route_setting :lifecycle for generally available endpoints. See https://docs.gitlab.com/policy/development_stages_support/
      RUBY
    end

    it 'registers an offense for other invalid symbols' do
      expect_offense(<<~RUBY)
        route_setting :lifecycle, :stable
                                  ^^^^^^^ Invalid lifecycle value `:stable`. Use one of: :beta, :experiment. Omit route_setting :lifecycle for generally available endpoints. See https://docs.gitlab.com/policy/development_stages_support/
      RUBY
    end

    it 'registers an offense for integer value' do
      expect_offense(<<~RUBY)
        route_setting :lifecycle, 1
                                  ^ Invalid lifecycle value `1`. Use one of: :beta, :experiment. Omit route_setting :lifecycle for generally available endpoints. See https://docs.gitlab.com/policy/development_stages_support/
      RUBY
    end

    it 'registers an offense inside nested blocks' do
      expect_offense(<<~RUBY)
        namespace :api do
          resources :users do
            route_setting :lifecycle, :deprecated
                                      ^^^^^^^^^^^ Invalid lifecycle value `:deprecated`. Use one of: :beta, :experiment. Omit route_setting :lifecycle for generally available endpoints. See https://docs.gitlab.com/policy/development_stages_support/
          end
        end
      RUBY
    end
  end

  context 'with other route_setting keys' do
    it 'does not register an offense for :authentication' do
      expect_no_offenses(<<~RUBY)
        route_setting :authentication, job_token_allowed: true
      RUBY
    end

    it 'does not register an offense for :authorization' do
      expect_no_offenses(<<~RUBY)
        route_setting :authorization, permissions: :read_user
      RUBY
    end
  end
end
