# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../../rubocop/cop/gitlab/authz/disallow_ability_allowed'

RSpec.describe RuboCop::Cop::Gitlab::Authz::DisallowAbilityAllowed, feature_category: :permissions do
  it 'flags Ability.allowed? calls' do
    expect_offense(<<~RUBY)
      condition(:can_read) { Ability.allowed?(user, :read_project, project) }
                             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not use `Ability.allowed?` in policy files. Use `can?` or define a condition using DeclarativePolicy primitives instead.
    RUBY
  end

  it 'flags Ability.allowed? with top-level cbase' do
    expect_offense(<<~RUBY)
      ::Ability.allowed?(user, :read_project, project)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not use `Ability.allowed?` in policy files. Use `can?` or define a condition using DeclarativePolicy primitives instead.
    RUBY
  end

  it 'flags .can? called on an explicit receiver' do
    expect_offense(<<~RUBY)
      condition(:can_read) { user.can?(:read_project, project) }
                             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not call `.can?` on an object in policy files. Use the bare `can?` helper from DeclarativePolicy instead.
    RUBY
  end

  it 'flags .can? called on any receiver, not just user' do
    expect_offense(<<~RUBY)
      current_user.can?(:admin_project, project)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not call `.can?` on an object in policy files. Use the bare `can?` helper from DeclarativePolicy instead.
    RUBY
  end

  it 'flags &.can? called with safe navigation operator' do
    expect_offense(<<~RUBY)
      condition(:can_read) { @user&.can?(:read_project, project) }
                             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not call `.can?` on an object in policy files. Use the bare `can?` helper from DeclarativePolicy instead.
    RUBY
  end

  it 'does not flag bare can? calls' do
    expect_no_offenses(<<~RUBY)
      condition(:can_read) { can?(:read_project, project) }
    RUBY
  end

  it 'does not flag unrelated Ability method calls' do
    expect_no_offenses(<<~RUBY)
      Ability.policy_for(user, project)
    RUBY
  end
end
