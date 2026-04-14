# frozen_string_literal: true

require 'rubocop_spec_helper'

require_relative '../../../../rubocop/cop/gettext/parameter_count'

RSpec.describe RuboCop::Cop::Gettext::ParameterCount, feature_category: :internationalization do
  describe '#_()' do
    it 'does not flag correct use' do
      expect_no_offenses(<<~RUBY)
        _('Hello')
        _(var)
      RUBY
    end

    it 'flags when called with no parameters' do
      expect_offense(<<~RUBY)
        _()
        ^^^ The `_(...)` method accepts exactly 1 parameter, but got 0.
      RUBY
    end

    it 'flags when called with more than 1 parameter' do
      expect_offense(<<~RUBY)
        _('Hello', 'extra')
        ^^^^^^^^^^^^^^^^^^^ The `_(...)` method accepts exactly 1 parameter, but got 2.
      RUBY
    end
  end

  describe '#s_()' do
    it 'does not flag correct use' do
      expect_no_offenses(<<~RUBY)
        s_('Namespace|Hello')
        s_(var)
      RUBY
    end

    it 'flags when called with no parameters' do
      expect_offense(<<~RUBY)
        s_()
        ^^^^ The `s_(...)` method accepts exactly 1 parameter, but got 0.
      RUBY
    end

    it 'flags when called with more than 1 parameter' do
      expect_offense(<<~RUBY)
        s_('Namespace|Hello', 'extra')
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ The `s_(...)` method accepts exactly 1 parameter, but got 2.
      RUBY
    end
  end

  describe '#n_()' do
    it 'does not flag correct use' do
      expect_no_offenses(<<~RUBY)
        n_('Apple', 'Apples', count)
        n_('Apple', 'Apples', 3)
      RUBY
    end

    it 'flags when called with fewer than 3 parameters' do
      expect_offense(<<~RUBY)
        n_('Apple', 'Apples')
        ^^^^^^^^^^^^^^^^^^^^^ The `n_(...)` method accepts exactly 3 parameters, but got 2.
      RUBY
    end

    it 'flags when called with more than 3 parameters' do
      expect_offense(<<~RUBY)
        n_('Apple', 'Apples', count, 'extra')
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ The `n_(...)` method accepts exactly 3 parameters, but got 4.
      RUBY
    end

    it 'flags when called with no parameters' do
      expect_offense(<<~RUBY)
        n_()
        ^^^^ The `n_(...)` method accepts exactly 3 parameters, but got 0.
      RUBY
    end
  end
end
