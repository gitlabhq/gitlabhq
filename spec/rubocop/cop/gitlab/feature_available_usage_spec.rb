# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/gitlab/feature_available_usage'

RSpec.describe RuboCop::Cop::Gitlab::FeatureAvailableUsage do
  context 'one argument given' do
    it 'does not flag the use of License.feature_available?' do
      expect_no_offenses('License.feature_available?(:push_rules)')
    end

    it 'does not flag the use of Gitlab::Saas.feature_available?' do
      expect_no_offenses('Gitlab::Saas.feature_available?(:some_feature)')
    end

    it 'flags the use with a dynamic feature as nil' do
      expect_offense(<<~RUBY)
        feature_available?(nil)
        ^^^^^^^^^^^^^^^^^^^^^^^ `feature_available?` should not be called for features that can be licensed (`nil` given), use `licensed_feature_available?(feature)` instead.
      RUBY
      expect_offense(<<~RUBY)
        project.feature_available?(nil)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `feature_available?` should not be called for features that can be licensed (`nil` given), use `licensed_feature_available?(feature)` instead.
      RUBY
    end

    it 'flags the use with an OSS project feature' do
      expect_offense(<<~RUBY)
        project.feature_available?(:issues)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `feature_available?` should be called with two arguments: `feature` and `user`.
      RUBY
      expect_offense(<<~RUBY)
        feature_available?(:issues)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^ `feature_available?` should be called with two arguments: `feature` and `user`.
      RUBY
    end

    it 'flags the use with a feature that is not a project feature' do
      expect_offense(<<~RUBY)
        feature_available?(:foo)
        ^^^^^^^^^^^^^^^^^^^^^^^^ `feature_available?` should not be called for features that can be licensed (`:foo` given), use `licensed_feature_available?(feature)` instead.
      RUBY
      expect_offense(<<~RUBY)
        project.feature_available?(:foo)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `feature_available?` should not be called for features that can be licensed (`:foo` given), use `licensed_feature_available?(feature)` instead.
      RUBY
      expect_offense(<<~RUBY)
        feature_available?(foo)
        ^^^^^^^^^^^^^^^^^^^^^^^ `feature_available?` should not be called for features that can be licensed (`foo` isn't a literal so we cannot say if it's legit or not), using `licensed_feature_available?(feature)` may be more appropriate.
      RUBY
      expect_offense(<<~RUBY)
        foo = :feature
        feature_available?(foo)
        ^^^^^^^^^^^^^^^^^^^^^^^ `feature_available?` should not be called for features that can be licensed (`foo` isn't a literal so we cannot say if it's legit or not), using `licensed_feature_available?(feature)` may be more appropriate.
      RUBY
    end
  end

  context 'two arguments given' do
    it 'does not flag the use with an OSS project feature' do
      expect_no_offenses('feature_available?(:issues, user)')
      expect_no_offenses('project.feature_available?(:issues, user)')
    end

    it 'does not flag the use with an EE project feature' do
      expect_no_offenses('feature_available?(:requirements, user)')
      expect_no_offenses('project.feature_available?(:requirements, user)')
    end

    it 'flags the use with a dynamic feature as a method call with two args' do
      expect_offense(<<~RUBY)
        feature_available?(:foo, current_user)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `feature_available?` should not be called for features that can be licensed (`:foo` given), use `licensed_feature_available?(feature)` instead.
      RUBY
      expect_offense(<<~RUBY)
        project.feature_available?(:foo, current_user)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `feature_available?` should not be called for features that can be licensed (`:foo` given), use `licensed_feature_available?(feature)` instead.
      RUBY
      expect_offense(<<~RUBY)
        feature_available?(foo, current_user)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `feature_available?` should not be called for features that can be licensed (`foo` isn't a literal so we cannot say if it's legit or not), using `licensed_feature_available?(feature)` may be more appropriate.
      RUBY
      expect_offense(<<~RUBY)
        project.feature_available?(foo, current_user)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `feature_available?` should not be called for features that can be licensed (`foo` isn't a literal so we cannot say if it's legit or not), using `licensed_feature_available?(feature)` may be more appropriate.
      RUBY
    end
  end
end
