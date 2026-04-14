# frozen_string_literal: true

require 'rubocop_spec_helper'

require_relative '../../../../rubocop/cop/gettext/missing_namespace'

RSpec.describe RuboCop::Cop::Gettext::MissingNamespace, feature_category: :internationalization do
  it 'does not flag s_() with a namespace' do
    expect_no_offenses(<<~'RUBY')
      s_('Namespace|Hello')
      s_('Namespace|Hello %{name}')
      s_('Add passkey|Add passkey')
      s_('Time Display|System')
      s_('Wiki404|Page not found')
    RUBY
  end

  it 'does not flag s_() with a variable argument' do
    expect_no_offenses(<<~'RUBY')
      s_(var)
      s_(method_call)
      s_(CONST)
    RUBY
  end

  it 'does not flag _()' do
    expect_no_offenses(<<~'RUBY')
      _('Hello')
    RUBY
  end

  it 'flags s_() without a namespace and autocorrects to _()' do
    expect_offense(<<~'RUBY')
      s_('Hello')
      ^^ Use `_()` instead of `s_()` when no namespace is present in the string.
    RUBY

    expect_correction(<<~'RUBY')
      _('Hello')
    RUBY
  end

  it 'does not flag s_() when the argument is missing' do
    expect_no_offenses(<<~'RUBY')
      s_() # This is to satisfy undercoverage. In reality there is another cop that covers this bad use
    RUBY
  end

  it 'does not flag s_() when the argument is a pure interpolation' do
    expect_no_offenses(<<~'RUBY')
      s_("#{namespace}") # This is to satisfy undercoverage. In reality there is another cop that covers this bad use case.
    RUBY
  end

  it 'flags s_() with interpolated string and no namespace and autocorrects to _()' do
    expect_offense(<<~'RUBY')
      s_('Hello %{name}')
      ^^ Use `_()` instead of `s_()` when no namespace is present in the string.
    RUBY

    expect_correction(<<~'RUBY')
      _('Hello %{name}')
    RUBY
  end

  it 'flags s_() with a split string and no namespace and autocorrects to _()' do
    expect_offense(<<~'RUBY')
      s_('Hello' \
      ^^ Use `_()` instead of `s_()` when no namespace is present in the string.
         'World')
    RUBY

    expect_correction(<<~'RUBY')
      _('Hello' \
         'World')
    RUBY
  end

  it 'flags multiple offenses and autocorrects all' do
    expect_offense(<<~'RUBY')
      s_('Hello')
      ^^ Use `_()` instead of `s_()` when no namespace is present in the string.
      s_('World')
      ^^ Use `_()` instead of `s_()` when no namespace is present in the string.
      s_('Hello | World')
      ^^ Use `_()` instead of `s_()` when no namespace is present in the string.
      s_('Namespace|Correct')
      s_('Add passkey|Add passkey')
      s_('Test_i18n|Hello')
    RUBY

    expect_correction(<<~'RUBY')
      _('Hello')
      _('World')
      _('Hello | World')
      s_('Namespace|Correct')
      s_('Add passkey|Add passkey')
      s_('Test_i18n|Hello')
    RUBY
  end
end
