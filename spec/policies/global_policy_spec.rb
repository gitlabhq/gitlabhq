# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GlobalPolicy do
  include TermsHelper

  let_it_be(:project_bot) { create(:user, :project_bot) }
  let_it_be(:migration_bot) { create(:user, :migration_bot) }
  let_it_be(:security_bot) { create(:user, :security_bot) }

  let(:current_user) { create(:user) }
  let(:user) { create(:user) }

  subject { described_class.new(current_user, [user]) }

  describe "reading the list of users" do
    context "for a logged in user" do
      it { is_expected.to be_allowed(:read_users_list) }
    end

    context "for an anonymous user" do
      let(:current_user) { nil }

      context "when the public level is restricted" do
        before do
          stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::PUBLIC])
        end

        it { is_expected.not_to be_allowed(:read_users_list) }
      end

      context "when the public level is not restricted" do
        before do
          stub_application_setting(restricted_visibility_levels: [])
        end

        it { is_expected.to be_allowed(:read_users_list) }
      end
    end

    context "for an admin" do
      let(:current_user) { create(:admin) }

      context "when the public level is restricted" do
        before do
          stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::PUBLIC])
        end

        it { is_expected.to be_allowed(:read_users_list) }
      end

      context "when the public level is not restricted" do
        before do
          stub_application_setting(restricted_visibility_levels: [])
        end

        it { is_expected.to be_allowed(:read_users_list) }
      end
    end
  end

  describe "create fork" do
    context "when user has not exceeded project limit" do
      it { is_expected.to be_allowed(:create_fork) }
    end

    context "when user has exceeded project limit" do
      let(:current_user) { create(:user, projects_limit: 0) }

      it { is_expected.not_to be_allowed(:create_fork) }
    end

    context "when user is a maintainer in a group" do
      let(:group) { create(:group) }
      let(:current_user) { create(:user, projects_limit: 0) }

      before do
        group.add_maintainer(current_user)
      end

      it { is_expected.to be_allowed(:create_fork) }
    end
  end

  describe 'create group' do
    context 'when user has the ability to create group' do
      let(:current_user) { create(:user, can_create_group: true) }

      it { is_expected.to be_allowed(:create_group) }
    end

    context 'when user does not have the ability to create group' do
      let(:current_user) { create(:user, can_create_group: false) }

      it { is_expected.not_to be_allowed(:create_group) }
    end
  end

  describe 'create group with default branch protection' do
    context 'when user has the ability to create group' do
      let(:current_user) { create(:user, can_create_group: true) }

      it { is_expected.to be_allowed(:create_group_with_default_branch_protection) }
    end

    context 'when user does not have the ability to create group' do
      let(:current_user) { create(:user, can_create_group: false) }

      it { is_expected.not_to be_allowed(:create_group_with_default_branch_protection) }
    end
  end

  describe 'custom attributes' do
    context 'regular user' do
      it { is_expected.not_to be_allowed(:read_custom_attribute) }
      it { is_expected.not_to be_allowed(:update_custom_attribute) }
    end

    context 'admin' do
      let(:current_user) { create(:user, :admin) }

      context 'when admin mode is enabled', :enable_admin_mode do
        it { is_expected.to be_allowed(:read_custom_attribute) }
        it { is_expected.to be_allowed(:update_custom_attribute) }
      end

      context 'when admin mode is disabled' do
        it { is_expected.to be_disallowed(:read_custom_attribute) }
        it { is_expected.to be_disallowed(:update_custom_attribute) }
      end
    end
  end

  describe 'approving users' do
    context 'regular user' do
      it { is_expected.not_to be_allowed(:approve_user) }
    end

    context 'admin' do
      let(:current_user) { create(:admin) }

      context 'when admin mode is enabled', :enable_admin_mode do
        it { is_expected.to be_allowed(:approve_user) }
      end

      context 'when admin mode is disabled' do
        it { is_expected.to be_disallowed(:approve_user) }
      end
    end
  end

  describe 'rejecting users' do
    context 'regular user' do
      it { is_expected.not_to be_allowed(:reject_user) }
    end

    context 'admin' do
      let(:current_user) { create(:admin) }

      context 'when admin mode is enabled', :enable_admin_mode do
        it { is_expected.to be_allowed(:reject_user) }
      end

      context 'when admin mode is disabled' do
        it { is_expected.to be_disallowed(:reject_user) }
      end
    end
  end

  describe 'using project statistics filters' do
    context 'regular user' do
      it { is_expected.not_to be_allowed(:use_project_statistics_filters) }
    end

    context 'admin' do
      let(:current_user) { create(:user, :admin) }

      context 'when admin mode is enabled', :enable_admin_mode do
        it { is_expected.to be_allowed(:use_project_statistics_filters) }
      end

      context 'when admin mode is disabled' do
        it { is_expected.to be_disallowed(:use_project_statistics_filters) }
      end
    end
  end

  shared_examples 'access allowed when terms accepted' do |ability|
    it { is_expected.not_to be_allowed(ability) }

    it "allows #{ability} when the user accepted the terms" do
      accept_terms(current_user)

      is_expected.to be_allowed(ability)
    end
  end

  describe 'API access' do
    context 'regular user' do
      it { is_expected.to be_allowed(:access_api) }
    end

    context 'admin' do
      let(:current_user) { create(:admin) }

      it { is_expected.to be_allowed(:access_api) }
    end

    context 'anonymous' do
      let(:current_user) { nil }

      it { is_expected.to be_allowed(:access_api) }
    end

    context 'project bot' do
      let(:current_user) { project_bot }

      it { is_expected.to be_allowed(:access_api) }
    end

    context 'migration bot' do
      let(:current_user) { migration_bot }

      it { is_expected.not_to be_allowed(:access_api) }
    end

    context 'security bot' do
      let(:current_user) { security_bot }

      it { is_expected.not_to be_allowed(:access_api) }
    end

    context 'user blocked pending approval' do
      before do
        current_user.block_pending_approval
      end

      it { is_expected.not_to be_allowed(:access_api) }
    end

    context 'with a deactivated user' do
      before do
        current_user.deactivate!
      end

      it { is_expected.not_to be_allowed(:access_api) }
    end

    context 'user with expired password' do
      before do
        current_user.update!(password_expires_at: 2.minutes.ago)
      end

      it { is_expected.not_to be_allowed(:access_api) }

      context 'when user is using ldap' do
        before do
          allow(current_user).to receive(:ldap_user?).and_return(true)
        end

        it { is_expected.to be_allowed(:access_api) }
      end
    end

    context 'when terms are enforced' do
      before do
        enforce_terms
      end

      context 'regular user' do
        it_behaves_like 'access allowed when terms accepted', :access_api
      end

      context 'admin' do
        let(:current_user) { create(:admin) }

        it_behaves_like 'access allowed when terms accepted', :access_api
      end

      context 'anonymous' do
        let(:current_user) { nil }

        it { is_expected.to be_allowed(:access_api) }
      end
    end

    context 'inactive user' do
      before do
        current_user.update!(confirmed_at: nil, confirmation_sent_at: 5.days.ago)
      end

      context 'when within the confirmation grace period' do
        before do
          allow(User).to receive(:allow_unconfirmed_access_for).and_return(10.days)
        end

        it { is_expected.to be_allowed(:access_api) }
      end

      context 'when confirmation grace period is expired' do
        before do
          allow(User).to receive(:allow_unconfirmed_access_for).and_return(2.days)
        end

        it { is_expected.not_to be_allowed(:access_api) }
      end
    end
  end

  describe 'receive notifications' do
    describe 'regular user' do
      it { is_expected.to be_allowed(:receive_notifications) }
    end

    describe 'admin' do
      let(:current_user) { create(:admin) }

      it { is_expected.to be_allowed(:receive_notifications) }
    end

    describe 'anonymous' do
      let(:current_user) { nil }

      it { is_expected.not_to be_allowed(:receive_notifications) }
    end

    describe 'blocked user' do
      before do
        current_user.block
      end

      it { is_expected.not_to be_allowed(:receive_notifications) }
    end

    describe 'deactivated user' do
      before do
        current_user.deactivate
      end

      it { is_expected.not_to be_allowed(:receive_notifications) }
    end

    context 'project bot' do
      let(:current_user) { project_bot }

      it { is_expected.not_to be_allowed(:receive_notifications) }
    end

    context 'migration bot' do
      let(:current_user) { migration_bot }

      it { is_expected.not_to be_allowed(:receive_notifications) }
    end

    context 'user blocked pending approval' do
      before do
        current_user.block_pending_approval
      end

      it { is_expected.not_to be_allowed(:receive_notifications) }
    end
  end

  describe 'git access' do
    describe 'regular user' do
      it { is_expected.to be_allowed(:access_git) }
    end

    describe 'admin' do
      let(:current_user) { create(:admin) }

      it { is_expected.to be_allowed(:access_git) }
    end

    describe 'anonymous' do
      let(:current_user) { nil }

      it { is_expected.to be_allowed(:access_git) }
    end

    context 'migration bot' do
      let(:current_user) { migration_bot }

      it { is_expected.to be_allowed(:access_git) }
    end

    context 'security bot' do
      let(:current_user) { security_bot }

      it { is_expected.to be_allowed(:access_git) }
    end

    describe 'deactivated user' do
      before do
        current_user.deactivate
      end

      it { is_expected.not_to be_allowed(:access_git) }
    end

    describe 'inactive user' do
      before do
        current_user.update!(confirmed_at: nil)
      end

      it { is_expected.not_to be_allowed(:access_git) }
    end

    context 'when terms are enforced' do
      before do
        enforce_terms
      end

      context 'regular user' do
        it_behaves_like 'access allowed when terms accepted', :access_git
      end

      context 'admin' do
        let(:current_user) { create(:admin) }

        it_behaves_like 'access allowed when terms accepted', :access_git
      end

      context 'anonymous' do
        let(:current_user) { nil }

        it { is_expected.to be_allowed(:access_git) }
      end
    end

    context 'project bot' do
      let(:current_user) { project_bot }

      it { is_expected.to be_allowed(:access_git) }
    end

    context 'user blocked pending approval' do
      before do
        current_user.block_pending_approval
      end

      it { is_expected.not_to be_allowed(:access_git) }
    end

    context 'user with expired password' do
      before do
        current_user.update!(password_expires_at: 2.minutes.ago)
      end

      it { is_expected.not_to be_allowed(:access_git) }

      context 'when user is using ldap' do
        before do
          allow(current_user).to receive(:ldap_user?).and_return(true)
        end

        it { is_expected.to be_allowed(:access_git) }
      end
    end
  end

  describe 'read instance metadata' do
    context 'regular user' do
      it { is_expected.to be_allowed(:read_instance_metadata) }
    end

    context 'anonymous' do
      let(:current_user) { nil }

      it { is_expected.not_to be_allowed(:read_instance_metadata) }
    end
  end

  describe 'slash commands' do
    context 'regular user' do
      it { is_expected.to be_allowed(:use_slash_commands) }
    end

    context 'when internal' do
      let(:current_user) { User.ghost }

      it { is_expected.not_to be_allowed(:use_slash_commands) }
    end

    context 'when blocked' do
      before do
        current_user.block
      end

      it { is_expected.not_to be_allowed(:use_slash_commands) }
    end

    context 'when deactivated' do
      before do
        current_user.deactivate
      end

      it { is_expected.not_to be_allowed(:use_slash_commands) }
    end

    describe 'inactive user' do
      before do
        current_user.update!(confirmed_at: nil)
      end

      it { is_expected.not_to be_allowed(:use_slash_commands) }
    end

    context 'when access locked' do
      before do
        current_user.lock_access!
      end

      it { is_expected.not_to be_allowed(:use_slash_commands) }
    end

    context 'project bot' do
      let(:current_user) { project_bot }

      it { is_expected.to be_allowed(:use_slash_commands) }
    end

    context 'migration bot' do
      let(:current_user) { migration_bot }

      it { is_expected.not_to be_allowed(:use_slash_commands) }
    end

    context 'user blocked pending approval' do
      before do
        current_user.block_pending_approval
      end

      it { is_expected.not_to be_allowed(:use_slash_commands) }
    end

    context 'user with expired password' do
      before do
        current_user.update!(password_expires_at: 2.minutes.ago)
      end

      it { is_expected.not_to be_allowed(:use_slash_commands) }

      context 'when user is using ldap' do
        before do
          allow(current_user).to receive(:ldap_user?).and_return(true)
        end

        it { is_expected.to be_allowed(:use_slash_commands) }
      end
    end
  end

  describe 'create_snippet' do
    context 'when anonymous' do
      let(:current_user) { nil }

      it { is_expected.not_to be_allowed(:create_snippet) }
    end

    context 'regular user' do
      it { is_expected.to be_allowed(:create_snippet) }
    end

    context 'when external' do
      let(:current_user) { build(:user, :external) }

      it { is_expected.not_to be_allowed(:create_snippet) }
    end
  end

  describe 'log in' do
    context 'project bot' do
      let(:current_user) { project_bot }

      it { is_expected.not_to be_allowed(:log_in) }
    end

    context 'migration bot' do
      let(:current_user) { migration_bot }

      it { is_expected.not_to be_allowed(:log_in) }
    end

    context 'security bot' do
      let(:current_user) { security_bot }

      it { is_expected.not_to be_allowed(:log_in) }
    end

    context 'user blocked pending approval' do
      before do
        current_user.block_pending_approval
      end

      it { is_expected.not_to be_allowed(:log_in) }
    end
  end

  describe 'update_runners_registration_token' do
    context 'when anonymous' do
      let(:current_user) { nil }

      it { is_expected.not_to be_allowed(:update_runners_registration_token) }
    end

    context 'regular user' do
      it { is_expected.not_to be_allowed(:update_runners_registration_token) }
    end

    context 'when external' do
      let(:current_user) { build(:user, :external) }

      it { is_expected.not_to be_allowed(:update_runners_registration_token) }
    end

    context 'admin' do
      let(:current_user) { create(:admin) }

      context 'when admin mode is enabled', :enable_admin_mode do
        it { is_expected.to be_allowed(:update_runners_registration_token) }
      end

      context 'when admin mode is disabled' do
        it { is_expected.to be_disallowed(:update_runners_registration_token) }
      end
    end
  end
end
