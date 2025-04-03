# frozen_string_literal: true

require 'rubocop_spec_helper'

require_relative '../../../../rubocop/cop/gitlab/feature_flag_key_dynamic'

RSpec.describe RuboCop::Cop::Gitlab::FeatureFlagKeyDynamic, feature_category: :scalability do
  context 'when calling Feature.enabled?' do
    it 'registers an offense when using a variable as the first argument' do
      expect_offense(<<~RUBY)
        flag_name = :some_flag
        Feature.enabled?(flag_name)
                         ^^^^^^^^^ First argument to `Feature.enabled?` must be a literal symbol.
      RUBY
    end

    it 'registers an offense when using a method call as the first argument' do
      expect_offense(<<~RUBY)
        Feature.enabled?(get_flag_name)
                         ^^^^^^^^^^^^^ First argument to `Feature.enabled?` must be a literal symbol.
      RUBY
    end

    it 'registers an offense when using a string as the first argument' do
      expect_offense(<<~RUBY)
        Feature.enabled?('some_flag')
                         ^^^^^^^^^^^ First argument to `Feature.enabled?` must be a literal symbol.
      RUBY

      expect_correction(<<~RUBY)
        Feature.enabled?(:some_flag)
      RUBY
    end

    it 'does not register an offense when using a literal symbol' do
      expect_no_offenses(<<~RUBY)
        Feature.enabled?(:some_flag)
      RUBY
    end

    it 'does not register an offense when using a literal symbol with additional arguments' do
      expect_no_offenses(<<~RUBY)
        Feature.enabled?(:some_flag, project)
      RUBY
    end
  end

  context 'when calling Feature.disabled?' do
    it 'registers an offense when using a variable as the first argument' do
      expect_offense(<<~RUBY)
        flag_name = :some_flag
        Feature.disabled?(flag_name)
                          ^^^^^^^^^ First argument to `Feature.disabled?` must be a literal symbol.
      RUBY
    end

    it 'registers an offense when using a method call as the first argument' do
      expect_offense(<<~RUBY)
        Feature.disabled?(get_flag_name)
                          ^^^^^^^^^^^^^ First argument to `Feature.disabled?` must be a literal symbol.
      RUBY
    end

    it 'registers an offense when using a string as the first argument' do
      expect_offense(<<~RUBY)
        Feature.disabled?('some_flag')
                          ^^^^^^^^^^^ First argument to `Feature.disabled?` must be a literal symbol.
      RUBY

      expect_correction(<<~RUBY)
        Feature.disabled?(:some_flag)
      RUBY
    end

    it 'does not register an offense when using a literal symbol' do
      expect_no_offenses(<<~RUBY)
        Feature.disabled?(:some_flag)
      RUBY
    end
  end

  context 'with non-Feature methods' do
    it 'does not register an offense for methods on other objects' do
      expect_no_offenses(<<~RUBY)
        OtherClass.enabled?(flag_name)
        something.disabled?(flag_name)
      RUBY
    end
  end
end
