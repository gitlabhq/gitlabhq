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

  describe 'three-argument can?(user, permission, subject)' do
    describe 'with manage_* permission' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          can?(user, :manage_issue, issue)
                     ^^^^^^^^^^^^^ Avoid using coarse permission checks such as manage_* or admin_* permissions. Use granular permissions instead.
        RUBY
      end
    end

    describe 'with admin_* permission' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          can?(current_user, :admin_project, project)
                             ^^^^^^^^^^^^^^ Avoid using coarse permission checks such as manage_* or admin_* permissions. Use granular permissions instead.
        RUBY
      end
    end

    describe 'with role_access permission' do
      described_class::ACCESS_PERMISSIONS.each do |permission|
        it 'registers an offense' do
          expect_offense(<<~RUBY, permission: permission)
            can?(current_user, :%{permission}, project)
                               ^{permission}^ Role access permissions are not allowed for access checks.
          RUBY
        end
      end
    end

    describe 'with allowed permission' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          can?(current_user, :read_project, project)
        RUBY
      end
    end
  end

  describe 'authorize: keyword argument' do
    describe 'with manage_* permission' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          field :foo, Type, authorize: :manage_project
                                       ^^^^^^^^^^^^^^^ Avoid using coarse permission checks such as manage_* or admin_* permissions. Use granular permissions instead.
        RUBY
      end
    end

    describe 'with admin_* permission' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          field :foo, Type, authorize: :admin_project
                                       ^^^^^^^^^^^^^^ Avoid using coarse permission checks such as manage_* or admin_* permissions. Use granular permissions instead.
        RUBY
      end
    end

    describe 'with role_access permission' do
      described_class::ACCESS_PERMISSIONS.each do |permission|
        it 'registers an offense' do
          expect_offense(<<~RUBY, permission: permission)
            field :foo, Type, authorize: :%{permission}
                                         ^{permission}^ Role access permissions are not allowed for access checks.
          RUBY
        end
      end
    end

    describe 'with allowed permission' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          field :foo, Type, authorize: :read_project
        RUBY
      end
    end

    describe 'when authorize key is not a symbol value' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          field :foo, Type, authorize: some_method
        RUBY
      end
    end

    describe 'when key is not :authorize' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          field :foo, Type, label: :developer_access
        RUBY
      end
    end
  end

  describe 'authorize call (GraphQL class macro)' do
    describe 'with manage_* permission' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          authorize :manage_project
                    ^^^^^^^^^^^^^^^ Avoid using coarse permission checks such as manage_* or admin_* permissions. Use granular permissions instead.
        RUBY
      end
    end

    describe 'with admin_* permission' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          authorize :admin_project
                    ^^^^^^^^^^^^^^ Avoid using coarse permission checks such as manage_* or admin_* permissions. Use granular permissions instead.
        RUBY
      end
    end

    describe 'with role_access permission' do
      described_class::ACCESS_PERMISSIONS.each do |permission|
        it 'registers an offense' do
          expect_offense(<<~RUBY, permission: permission)
            authorize :%{permission}
                      ^{permission}^ Role access permissions are not allowed for access checks.
          RUBY
        end
      end
    end

    describe 'with allowed permission' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          authorize :read_project
        RUBY
      end
    end

    describe 'with multiple permissions where one is offending' do
      it 'registers an offense for the offending sym only' do
        expect_offense(<<~RUBY)
          authorize :read_project, :developer_access
                                   ^^^^^^^^^^^^^^^^^ Role access permissions are not allowed for access checks.
        RUBY
      end
    end
  end

  describe 'authorize! call (Grape API helper)' do
    describe 'with manage_* permission' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          authorize! :manage_project, project
                     ^^^^^^^^^^^^^^^ Avoid using coarse permission checks such as manage_* or admin_* permissions. Use granular permissions instead.
        RUBY
      end
    end

    describe 'with admin_* permission and parens' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          authorize!(:admin_project, project)
                     ^^^^^^^^^^^^^^ Avoid using coarse permission checks such as manage_* or admin_* permissions. Use granular permissions instead.
        RUBY
      end
    end

    describe 'with role_access permission' do
      described_class::ACCESS_PERMISSIONS.each do |permission|
        it 'registers an offense' do
          expect_offense(<<~RUBY, permission: permission)
            authorize! :%{permission}, project
                       ^{permission}^ Role access permissions are not allowed for access checks.
          RUBY
        end
      end
    end

    describe 'with allowed permission' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          authorize! :read_project, project
        RUBY
      end
    end
  end
end
