# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../../rubocop/cop/gitlab/authz/use_policy_helpers'

RSpec.describe RuboCop::Cop::Gitlab::Authz::UsePolicyHelpers, feature_category: :permissions do
  it 'does not flag expect_allowed' do
    expect_no_offenses(<<~RUBY)
      expect_allowed(:read_group)
    RUBY
  end

  it 'does not flag expect_disallowed' do
    expect_no_offenses(<<~RUBY)
      expect_disallowed(:read_group)
    RUBY
  end

  it 'flags is_expected.to allow_action(:read_group)' do
    expect_offense(<<~RUBY)
      is_expected.to allow_action(:read_group)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `expect_allowed` or `expect_disallowed` from `PolicyHelpers` instead of using `allow_action`, `be_allowed`, or `be_disallowed` directly.
    RUBY
  end

  it 'flags is_expected.not_to allow_action(:pages_multiple_versions)' do
    expect_offense(<<~RUBY)
      is_expected.not_to allow_action(:pages_multiple_versions)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `expect_allowed` or `expect_disallowed` from `PolicyHelpers` instead of using `allow_action`, `be_allowed`, or `be_disallowed` directly.
    RUBY
  end

  it 'flags is_expected.to be_allowed(:read_group)' do
    expect_offense(<<~RUBY)
      is_expected.to be_allowed(:read_group)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `expect_allowed` or `expect_disallowed` from `PolicyHelpers` instead of using `allow_action`, `be_allowed`, or `be_disallowed` directly.
    RUBY
  end

  it 'flags is_expected.not_to be_allowed(:read_group)' do
    expect_offense(<<~RUBY)
      is_expected.not_to be_allowed(:read_group)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `expect_allowed` or `expect_disallowed` from `PolicyHelpers` instead of using `allow_action`, `be_allowed`, or `be_disallowed` directly.
    RUBY
  end

  it 'flags expect(policy).to be_disallowed(:read_group)' do
    expect_offense(<<~RUBY)
      expect(policy).to be_disallowed(:read_group)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `expect_allowed` or `expect_disallowed` from `PolicyHelpers` instead of using `allow_action`, `be_allowed`, or `be_disallowed` directly.
    RUBY
  end
end
