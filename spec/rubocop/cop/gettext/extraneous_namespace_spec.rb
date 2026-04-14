# frozen_string_literal: true

require 'rubocop_spec_helper'

require_relative '../../../../rubocop/cop/gettext/extraneous_namespace'

RSpec.describe RuboCop::Cop::Gettext::ExtraneousNamespace, feature_category: :internationalization do
  it 'does not flag _() without a namespace' do
    expect_no_offenses(<<~'RUBY')
      _('Hello')
      _('Hello %{name}')
      _('Hello | World')
      _('Example: (feature|hotfix)\/.*')
      _('Example: (jar|exe)$')
    RUBY
  end

  it 'does not flag s_() with a namespace' do
    expect_no_offenses(<<~'RUBY')
      s_('Namespace|Hello')
      s_('Wiki404|Page not found')
      s_('Test_i18n|Hello')
      s_('Add passkey|Add passkey')
      s_('Time Display|System')
    RUBY
  end

  it 'flags _() with a namespace and autocorrects to s_()' do
    expect_offense(<<~'RUBY')
      _('Namespace|Hello')
      ^ Use `s_()` instead of `_()` when a namespace is present in the string.
    RUBY

    expect_correction(<<~'RUBY')
      s_('Namespace|Hello')
    RUBY
  end

  it 'flags _() with a namespace and interpolation and autocorrects to s_()' do
    expect_offense(<<~'RUBY')
      _('Namespace|Hello %{name}')
      ^ Use `s_()` instead of `_()` when a namespace is present in the string.
    RUBY

    expect_correction(<<~'RUBY')
      s_('Namespace|Hello %{name}')
    RUBY
  end

  it 'flags _() with a namespace in a split string and autocorrects to s_()' do
    expect_offense(<<~'RUBY')
      _('Namespace|Hello' \
      ^ Use `s_()` instead of `_()` when a namespace is present in the string.
        'World')
    RUBY

    expect_correction(<<~'RUBY')
      s_('Namespace|Hello' \
        'World')
    RUBY
  end

  it 'does not flag when the argument is missing' do
    expect_no_offenses(<<~'RUBY')
      _() # This is to satisfy undercoverage. In reality there is another cop that covers this bad use
    RUBY
  end

  it 'does not flag when the argument is a symbol' do
    expect_no_offenses(<<~'RUBY')
      _(:foo) # This is to satisfy undercoverage. In reality there is another cop that covers this bad use
    RUBY
  end

  it 'does not flag when the argument is a pure interpolation' do
    expect_no_offenses(<<~'RUBY')
      _("#{namespace}") # This is to satisfy undercoverage. In reality there is another cop that covers this bad use case.
    RUBY
  end

  it 'flags multiple offenses and autocorrects all' do
    expect_offense(<<~'RUBY')
      _('Namespace|Hello')
      ^ Use `s_()` instead of `_()` when a namespace is present in the string.
      _('Namespace|World')
      ^ Use `s_()` instead of `_()` when a namespace is present in the string.
      _('No namespace')
      _('Hello | World')
    RUBY

    expect_correction(<<~'RUBY')
      s_('Namespace|Hello')
      s_('Namespace|World')
      _('No namespace')
      _('Hello | World')
    RUBY
  end

  it 'flags _() with numbers, underscores or spaces in namespace and autocorrects' do
    expect_offense(<<~'RUBY')
      _('Wiki404|Page not found')
      ^ Use `s_()` instead of `_()` when a namespace is present in the string.
      _('Test_i18n|Hello')
      ^ Use `s_()` instead of `_()` when a namespace is present in the string.
      _('Add passkey|Add passkey')
      ^ Use `s_()` instead of `_()` when a namespace is present in the string.
      _('Time Display|System')
      ^ Use `s_()` instead of `_()` when a namespace is present in the string.
    RUBY

    expect_correction(<<~'RUBY')
      s_('Wiki404|Page not found')
      s_('Test_i18n|Hello')
      s_('Add passkey|Add passkey')
      s_('Time Display|System')
    RUBY
  end
end
