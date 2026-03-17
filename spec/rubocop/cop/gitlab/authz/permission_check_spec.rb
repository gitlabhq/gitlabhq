# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../../rubocop/cop/gitlab/authz/permission_check'

RSpec.describe RuboCop::Cop::Gitlab::Authz::PermissionCheck, feature_category: :permissions do
  describe 'Ability.allowed? with manage_* permission' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        Ability.allowed?(user, :manage_project, project)
                               ^^^^^^^^^^^^^^^ Avoid using coarse permission checks such as manage_* or admin_* permissions. Use granular permissions instead.
      RUBY
    end
  end

  describe 'Ability.allowed? with admin_* permission' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        Ability&.allowed?(user, :admin_user, target)
                                ^^^^^^^^^^^ Avoid using coarse permission checks such as manage_* or admin_* permissions. Use granular permissions instead.
      RUBY
    end
  end

  describe 'Ability.allowed? with role_access permission' do
    described_class::ACCESS_PERMISSIONS.each do |permission|
      it 'registers an offense' do
        expect_offense(<<~RUBY, permission: permission)
          Ability.allowed?(user, :%{permission}, target)
                                 ^{permission}^ Role access permissions are not allowed for access checks.
        RUBY
      end
    end
  end

  describe 'Ability.allowed? with read_* permission' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        Ability.allowed?(user, :read_project, project)
      RUBY
    end
  end

  describe 'Ability.allowed? with create_* permission' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        Ability.allowed?(user, :read_note, note)
      RUBY
    end
  end

  describe 'user.can? with manage_* permission' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        user.can?(:manage_issue, issue)
                  ^^^^^^^^^^^^^ Avoid using coarse permission checks such as manage_* or admin_* permissions. Use granular permissions instead.
      RUBY
    end
  end

  describe 'user&.can? with manage_* permission' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        user&.can?(:manage_issue, issue)
                   ^^^^^^^^^^^^^ Avoid using coarse permission checks such as manage_* or admin_* permissions. Use granular permissions instead.
      RUBY
    end
  end

  describe 'empty can? with admin_* permission' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        can?(:admin_issue, issue)
             ^^^^^^^^^^^^ Avoid using coarse permission checks such as manage_* or admin_* permissions. Use granular permissions instead.
      RUBY
    end
  end

  describe 'can? with one argument' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        can?(:admin_issue)
             ^^^^^^^^^^^^ Avoid using coarse permission checks such as manage_* or admin_* permissions. Use granular permissions instead.
      RUBY
    end
  end

  describe 'user.can? with role_access permission' do
    described_class::ACCESS_PERMISSIONS.each do |permission|
      it 'registers an offense' do
        expect_offense(<<~RUBY, permission: permission)
          user.can?(:%{permission}, target)
                    ^{permission}^ Role access permissions are not allowed for access checks.
        RUBY
      end
    end
  end

  describe 'user.can? with allowed permission' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        user.can?(:create_issue, issue)
      RUBY
    end
  end
end
