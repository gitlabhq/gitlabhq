# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/gitlab/users_internal_organization'

RSpec.describe RuboCop::Cop::Gitlab::UsersInternalOrganization, feature_category: :user_profile do
  it 'registers an offense for direct Users::Internal.alert_bot call' do
    expect_offense(<<~RUBY)
      Users::Internal.alert_bot
      ^^^^^^^^^^^^^^^^^^^^^^^^^ Use `Users::Internal.in_organization(organization)` before calling methods on `Users::Internal`.
    RUBY
  end

  it 'registers an offense for direct Users::Internal.support_bot call' do
    expect_offense(<<~RUBY)
      Users::Internal.support_bot
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `Users::Internal.in_organization(organization)` before calling methods on `Users::Internal`.
    RUBY
  end

  it 'registers an offense for direct Users::Internal.ghost call' do
    expect_offense(<<~RUBY)
      Users::Internal.ghost
      ^^^^^^^^^^^^^^^^^^^^^ Use `Users::Internal.in_organization(organization)` before calling methods on `Users::Internal`.
    RUBY
  end

  it 'registers an offense for non-fully qualified Internal.alert_bot call' do
    expect_offense(<<~RUBY)
      Internal.alert_bot
      ^^^^^^^^^^^^^^^^^^ Use `Users::Internal.in_organization(organization)` before calling methods on `Users::Internal`.
    RUBY
  end

  it 'registers an offense for non-fully qualified Internal.support_bot call' do
    expect_offense(<<~RUBY)
      Internal.support_bot
      ^^^^^^^^^^^^^^^^^^^^ Use `Users::Internal.in_organization(organization)` before calling methods on `Users::Internal`.
    RUBY
  end

  it 'registers an offense for support_bot_id' do
    expect_offense(<<~RUBY)
      Users::Internal.support_bot_id
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `Users::Internal.in_organization(organization)` before calling methods on `Users::Internal`.
    RUBY
  end

  it 'does not register an offense for bot_avatar' do
    expect_no_offenses(<<~RUBY)
      Users::Internal.bot_avatar(image: 'test.png')
    RUBY
  end

  it 'does not register an offense for prepend_mod' do
    expect_no_offenses(<<~RUBY)
      Users::Internal.prepend_mod
    RUBY
  end

  it 'does not register an offense for prepend' do
    expect_no_offenses(<<~RUBY)
      Users::Internal.prepend(SomeModule)
    RUBY
  end

  it 'does not register an offense for try' do
    expect_no_offenses(<<~RUBY)
      Users::Internal.try(:visual_review_bot)
    RUBY
  end

  it 'does not register an offense for clear_memoization' do
    expect_no_offenses(<<~RUBY)
      Users::Internal.clear_memoization(:support_bot_id)
    RUBY
  end

  it 'registers an offense for visual_review_bot' do
    expect_offense(<<~RUBY)
      Users::Internal.visual_review_bot
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `Users::Internal.in_organization(organization)` before calling methods on `Users::Internal`.
    RUBY
  end

  it 'does not register an offense for in_organization usage' do
    expect_no_offenses(<<~RUBY)
      Users::Internal.in_organization(organization).alert_bot
    RUBY
  end

  it 'does not register an offense for in_organization method itself' do
    expect_no_offenses(<<~RUBY)
      Users::Internal.in_organization(organization)
    RUBY
  end

  it 'does not register an offense for Internal.in_organization' do
    expect_no_offenses(<<~RUBY)
      Internal.in_organization(organization)
    RUBY
  end
end
