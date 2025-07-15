# frozen_string_literal: true

require 'rubocop_spec_helper'

require_relative '../../../../rubocop/cop/gitlab/feature_flag_without_actor'

RSpec.describe RuboCop::Cop::Gitlab::FeatureFlagWithoutActor, feature_category: :scalability do
  let(:msg) { described_class::MSG }

  context 'when calling Feature.enabled?' do
    it 'registers offense' do
      expect_offense(<<~RUBY)
        Feature.enabled?(:fflag)
        ^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
      RUBY
    end

    it 'registers offense when called with type parameter' do
      expect_offense(<<~RUBY)
        Feature.enabled?(:fflag, type: :ops)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
      RUBY
    end

    it 'registers offense when called with type and default_enabled_if_undefined parameter' do
      expect_offense(<<~RUBY)
        Feature.enabled?(:fflag, type: :development, default_enabled_if_undefined: nil)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
      RUBY
    end

    it 'registers offense when called under global namespace' do
      expect_offense(<<~RUBY)
        ::Feature.enabled?(:fflag, type: :ops)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
      RUBY
    end

    it 'registers no offense when called with an actor' do
      expect_no_offenses(<<~RUBY)
        ::Feature.enabled?(:fflag, thing, type: :ops)
      RUBY
    end

    it 'registers no offense when called with an actor and other args' do
      expect_no_offenses(<<~RUBY)
        ::Feature.enabled?(:fflag, thing, type: :development, default_enabled_if_undefined: nil)
      RUBY
    end
  end

  context 'when calling Feature.disabled?' do
    it 'registers offense' do
      expect_offense(<<~RUBY)
        Feature.disabled?(:fflag)
        ^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
      RUBY
    end

    it 'registers offense when called with type parameter' do
      expect_offense(<<~RUBY)
        Feature.disabled?(:fflag, type: :ops)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
      RUBY
    end

    it 'registers offense when called under global namespace' do
      expect_offense(<<~RUBY)
        ::Feature.disabled?(:fflag, type: :ops)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
      RUBY
    end

    it 'registers no offense when called with an actor' do
      expect_no_offenses(<<~RUBY)
        ::Feature.disabled?(:fflag, thing, type: :ops)
      RUBY
    end

    it 'registers no offense when called with an actor and other args' do
      expect_no_offenses(<<~RUBY)
        ::Feature.disabled?(:fflag, thing, type: :development, default_enabled_if_undefined: nil)
      RUBY
    end
  end
end
