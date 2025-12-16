# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../../rubocop/cop/gitlab/rspec/avoid_create_default_organization'

RSpec.describe RuboCop::Cop::Gitlab::RSpec::AvoidCreateDefaultOrganization, feature_category: :organization do
  include RuboCop::RSpec::ExpectOffense

  let(:message) do
    "Do not use the `:default` trait when creating organizations. See https://docs.gitlab.com/development/organization/#the-default-organization."
  end

  describe 'bad examples' do
    it 'registers an offense when using :default trait' do
      expect_offense(<<~RUBY)
        create(:organization, :default)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{message}
      RUBY
    end

    it 'registers an offense when using :default trait with other traits' do
      expect_offense(<<~RUBY)
        create(:organization, :admin, :default)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{message}
      RUBY
    end

    it 'registers an offense when using :default trait in build' do
      expect_offense(<<~RUBY)
        build(:organization, :default)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{message}
      RUBY
    end

    it 'registers an offense when using :default trait in create_list' do
      expect_offense(<<~RUBY)
        create_list(:organization, 3, :default)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{message}
      RUBY
    end

    it 'registers an offense when using :default trait with attributes' do
      expect_offense(<<~RUBY)
        create(:organization, :default, name: "Acme")
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{message}
      RUBY
    end

    it 'registers an offense when receiver is FactoryBot' do
      expect_offense(<<~RUBY)
        FactoryBot.create(:organization, :default)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{message}
      RUBY
    end
  end

  describe 'good examples' do
    it 'does not register an offense when not using :default trait' do
      expect_no_offenses(<<~RUBY)
        create(:organization)
      RUBY
    end

    it 'does not register an offense when using other traits' do
      expect_no_offenses(<<~RUBY)
        create(:organization, :admin)
      RUBY
    end

    it 'does not register an offense when using other traits with attributes' do
      expect_no_offenses(<<~RUBY)
        create(:organization, :admin, name: "Acme")
      RUBY
    end

    it 'does not register an offense when the factory is not organization' do
      expect_no_offenses(<<~RUBY)
        create(:user, :default)
      RUBY
    end
  end
end
