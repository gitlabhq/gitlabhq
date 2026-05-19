# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/api/route_setting_tier'

RSpec.describe RuboCop::Cop::API::RouteSettingTier, :config, feature_category: :api do
  context 'with valid tier values' do
    it 'does not register an offense for :premium' do
      expect_no_offenses(<<~RUBY)
        route_setting :tier, :premium
      RUBY
    end

    it 'does not register an offense for :ultimate' do
      expect_no_offenses(<<~RUBY)
        route_setting :tier, :ultimate
      RUBY
    end

    it 'does not register an offense inside a namespace block' do
      expect_no_offenses(<<~RUBY)
        namespace :users do
          route_setting :tier, :premium
          get ':id' do
          end
        end
      RUBY
    end

    it 'does not register an offense inside a resource block' do
      expect_no_offenses(<<~RUBY)
        resources :projects do
          route_setting :tier, :ultimate
        end
      RUBY
    end
  end

  context 'with invalid tier values' do
    it 'registers an offense for :free' do
      expect_offense(<<~RUBY)
        route_setting :tier, :free
                             ^^^^^ Invalid tier value ':free'. Use :premium or :ultimate. CE endpoints are implicitly Free and do not need a tier annotation.
      RUBY
    end

    it 'registers an offense for legacy tier name :gold' do
      expect_offense(<<~RUBY)
        route_setting :tier, :gold
                             ^^^^^ Invalid tier value ':gold'. Use :premium or :ultimate. CE endpoints are implicitly Free and do not need a tier annotation.
      RUBY
    end

    it 'registers an offense for legacy tier name :silver' do
      expect_offense(<<~RUBY)
        route_setting :tier, :silver
                             ^^^^^^^ Invalid tier value ':silver'. Use :premium or :ultimate. CE endpoints are implicitly Free and do not need a tier annotation.
      RUBY
    end

    it 'registers an offense for legacy tier name :starter' do
      expect_offense(<<~RUBY)
        route_setting :tier, :starter
                             ^^^^^^^^ Invalid tier value ':starter'. Use :premium or :ultimate. CE endpoints are implicitly Free and do not need a tier annotation.
      RUBY
    end

    it 'registers an offense for legacy tier name :bronze' do
      expect_offense(<<~RUBY)
        route_setting :tier, :bronze
                             ^^^^^^^ Invalid tier value ':bronze'. Use :premium or :ultimate. CE endpoints are implicitly Free and do not need a tier annotation.
      RUBY
    end

    it 'registers an offense for string instead of symbol' do
      expect_offense(<<~RUBY)
        route_setting :tier, 'premium'
                             ^^^^^^^^^ Invalid tier value ''premium''. Use :premium or :ultimate. CE endpoints are implicitly Free and do not need a tier annotation.
      RUBY
    end

    it 'registers an offense for arbitrary symbol' do
      expect_offense(<<~RUBY)
        route_setting :tier, :enterprise
                             ^^^^^^^^^^^ Invalid tier value ':enterprise'. Use :premium or :ultimate. CE endpoints are implicitly Free and do not need a tier annotation.
      RUBY
    end

    it 'registers an offense for integer value' do
      expect_offense(<<~RUBY)
        route_setting :tier, 1
                             ^ Invalid tier value '1'. Use :premium or :ultimate. CE endpoints are implicitly Free and do not need a tier annotation.
      RUBY
    end

    it 'registers an offense inside nested blocks' do
      expect_offense(<<~RUBY)
        namespace :api do
          resources :users do
            route_setting :tier, :gold
                                 ^^^^^ Invalid tier value ':gold'. Use :premium or :ultimate. CE endpoints are implicitly Free and do not need a tier annotation.
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

    it 'does not register an offense for :lifecycle' do
      expect_no_offenses(<<~RUBY)
        route_setting :lifecycle, :beta
      RUBY
    end
  end
end
