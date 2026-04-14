# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../../rubocop/cop/gitlab/authz/avoid_highest_role_usage'

RSpec.describe RuboCop::Cop::Gitlab::Authz::AvoidHighestRoleUsage, feature_category: :permissions do
  it 'flags @user.highest_role calls' do
    expect_offense(<<~RUBY)
      condition(:is_developer) { @user.highest_role >= Gitlab::Access::DEVELOPER }
                                 ^^^^^^^^^^^^^^^^^^ Do not use `highest_role` in policy files. It returns the highest role a user has anywhere on the instance and is unsafe for authorization. Use subject-scoped access level checks instead, such as `team_access_level` or `project.team.developer?(user)`.
    RUBY
  end

  it 'flags user.highest_role calls' do
    expect_offense(<<~RUBY)
      condition(:is_developer) { user.highest_role >= Gitlab::Access::DEVELOPER }
                                 ^^^^^^^^^^^^^^^^^ Do not use `highest_role` in policy files. It returns the highest role a user has anywhere on the instance and is unsafe for authorization. Use subject-scoped access level checks instead, such as `team_access_level` or `project.team.developer?(user)`.
    RUBY
  end

  it 'flags highest_role called on any receiver' do
    expect_offense(<<~RUBY)
      current_user.highest_role
      ^^^^^^^^^^^^^^^^^^^^^^^^^ Do not use `highest_role` in policy files. It returns the highest role a user has anywhere on the instance and is unsafe for authorization. Use subject-scoped access level checks instead, such as `team_access_level` or `project.team.developer?(user)`.
    RUBY
  end

  it 'flags &.highest_role called with safe navigation operator' do
    expect_offense(<<~RUBY)
      condition(:is_developer) { @user&.highest_role >= Gitlab::Access::DEVELOPER }
                                 ^^^^^^^^^^^^^^^^^^^ Do not use `highest_role` in policy files. It returns the highest role a user has anywhere on the instance and is unsafe for authorization. Use subject-scoped access level checks instead, such as `team_access_level` or `project.team.developer?(user)`.
    RUBY
  end

  it 'does not flag team_access_level checks' do
    expect_no_offenses(<<~RUBY)
      condition(:is_developer) { team_access_level >= Gitlab::Access::DEVELOPER }
    RUBY
  end

  it 'does not flag project team membership checks' do
    expect_no_offenses(<<~RUBY)
      condition(:is_developer) { project.team.developer?(user) }
    RUBY
  end

  it 'does not flag unrelated role method calls' do
    expect_no_offenses(<<~RUBY)
      condition(:is_guest) { user.access_level >= Gitlab::Access::GUEST }
    RUBY
  end
end
