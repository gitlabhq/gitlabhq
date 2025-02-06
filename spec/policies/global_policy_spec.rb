# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GlobalPolicy, feature_category: :shared do
  include TermsHelper

  HasUserType::BOT_USER_TYPES.each do |type| # rubocop:disable RSpec/UselessDynamicDefinition -- False positive
    type_sym = type.to_sym
    let_it_be(type_sym) { create(:user, type_sym) }
  end

  let_it_be(:admin_user) { create(:admin) }
  let_it_be_with_reload(:current_user) { create(:user) }
  let_it_be(:user) { create(:user) }

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

        it { is_expected.to be_disallowed(:read_users_list) }
      end

      context "when the public level is not restricted" do
        before do
          stub_application_setting(restricted_visibility_levels: [])
        end

        it { is_expected.to be_allowed(:read_users_list) }
      end
    end

    context "for an admin" do
      let(:current_user) { admin_user }

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

  describe 'create group' do
    context 'when user has the ability to create group' do
      let(:current_user) { create(:user, can_create_group: true) }

      it { is_expected.to be_allowed(:create_group) }

      context 'when can_create_group_and_projects returns true' do
        before do
          allow(current_user).to receive(:allow_user_to_create_group_and_project?).and_return(true)
        end

        it { is_expected.to be_allowed(:create_group) }
      end

      context 'when can_create_group_and_projects returns false' do
        before do
          allow(current_user).to receive(:allow_user_to_create_group_and_project?).and_return(false)
        end

        it { is_expected.to be_disallowed(:create_group) }
      end
    end

    context 'when user does not have the ability to create group' do
      let(:current_user) { create(:user, can_create_group: false) }

      it { is_expected.to be_disallowed(:create_group) }
    end
  end

  describe 'create group with default branch protection' do
    context 'when user has the ability to create group' do
      let(:current_user) { create(:user, can_create_group: true) }

      it { is_expected.to be_allowed(:create_group_with_default_branch_protection) }
    end

    context 'when user does not have the ability to create group' do
      let(:current_user) { create(:user, can_create_group: false) }

      it { is_expected.to be_disallowed(:create_group_with_default_branch_protection) }
    end
  end

  describe 'custom attributes' do
    context 'regular user' do
      it { is_expected.to be_disallowed(:read_custom_attribute) }
      it { is_expected.to be_disallowed(:update_custom_attribute) }
    end

    context 'admin' do
      let(:current_user) { admin_user }

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
      it { is_expected.to be_disallowed(:approve_user) }
    end

    context 'admin' do
      let(:current_user) { admin_user }

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
      it { is_expected.to be_disallowed(:reject_user) }
    end

    context 'admin' do
      let(:current_user) { admin_user }

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
      it { is_expected.to be_disallowed(:use_project_statistics_filters) }
    end

    context 'admin' do
      let(:current_user) { admin_user }

      context 'when admin mode is enabled', :enable_admin_mode do
        it { is_expected.to be_allowed(:use_project_statistics_filters) }
      end

      context 'when admin mode is disabled' do
        it { is_expected.to be_disallowed(:use_project_statistics_filters) }
      end
    end
  end

  shared_examples 'access allowed when terms accepted' do |ability|
    it { is_expected.to be_disallowed(ability) }

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
      let(:current_user) { admin_user }

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

    context 'service account' do
      let(:current_user) { service_account }

      it { is_expected.to be_allowed(:access_api) }
    end

    context 'migration bot' do
      let(:current_user) { migration_bot }

      it { is_expected.to be_disallowed(:access_api) }
    end

    context 'security bot' do
      let(:current_user) { security_bot }

      it { is_expected.to be_disallowed(:access_api) }
    end

    context 'llm bot' do
      let(:current_user) { llm_bot }

      it { is_expected.to be_disallowed(:access_api) }
    end

    context 'user blocked pending approval' do
      before do
        current_user.block_pending_approval
      end

      it { is_expected.to be_disallowed(:access_api) }
    end

    context 'with a deactivated user' do
      before do
        current_user.deactivate!
      end

      it { is_expected.to be_disallowed(:access_api) }
    end

    context 'user with expired password' do
      before do
        current_user.update!(password_expires_at: 2.minutes.ago)
      end

      it { is_expected.to be_disallowed(:access_api) }

      context 'when user is using ldap' do
        let(:current_user) { create(:omniauth_user, provider: 'ldap', password_expires_at: 2.minutes.ago) }

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
        let(:current_user) { admin_user }

        it_behaves_like 'access allowed when terms accepted', :access_api
      end

      context 'anonymous' do
        let(:current_user) { nil }

        it { is_expected.to be_allowed(:access_api) }
      end
    end

    context 'inactive user' do
      before do
        stub_application_setting_enum('email_confirmation_setting', 'soft')
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

        it { is_expected.to be_disallowed(:access_api) }
      end
    end
  end

  describe 'receive notifications' do
    describe 'regular user' do
      it { is_expected.to be_allowed(:receive_notifications) }
    end

    describe 'admin' do
      let(:current_user) { admin_user }

      it { is_expected.to be_allowed(:receive_notifications) }
    end

    describe 'anonymous' do
      let(:current_user) { nil }

      it { is_expected.to be_disallowed(:receive_notifications) }
    end

    describe 'blocked user' do
      before do
        current_user.block
      end

      it { is_expected.to be_disallowed(:receive_notifications) }
    end

    describe 'deactivated user' do
      before do
        current_user.deactivate
      end

      it { is_expected.to be_disallowed(:receive_notifications) }
    end

    context 'project bot' do
      let(:current_user) { project_bot }

      it { is_expected.to be_disallowed(:receive_notifications) }
    end

    context 'service account' do
      let(:current_user) { service_account }

      it { is_expected.to be_disallowed(:receive_notifications) }

      context 'with custom email address starting with service account prefix' do
        let(:current_user) { build(:user, :service_account, email: 'service_account@example.com') }

        it { is_expected.to be_allowed(:receive_notifications) }
      end

      context 'with custom email address ending with no-reply domain' do
        let(:current_user) { build(:user, :service_account, email: "bot@#{User::NOREPLY_EMAIL_DOMAIN}") }

        it { is_expected.to be_allowed(:receive_notifications) }
      end
    end

    context 'migration bot' do
      let(:current_user) { migration_bot }

      it { is_expected.to be_disallowed(:receive_notifications) }
    end

    context 'user blocked pending approval' do
      before do
        current_user.block_pending_approval
      end

      it { is_expected.to be_disallowed(:receive_notifications) }
    end
  end

  describe 'git access' do
    describe 'regular user' do
      it { is_expected.to be_allowed(:access_git) }
    end

    describe 'admin' do
      let(:current_user) { admin_user }

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

      it { is_expected.to be_disallowed(:access_git) }
    end

    describe 'inactive user' do
      before do
        stub_application_setting_enum('email_confirmation_setting', 'soft')
        current_user.update!(confirmed_at: nil)
      end

      it { is_expected.to be_disallowed(:access_git) }
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

    context 'service account' do
      let(:current_user) { service_account }

      it { is_expected.to be_allowed(:access_git) }
    end

    context 'user blocked pending approval' do
      before do
        current_user.block_pending_approval
      end

      it { is_expected.to be_disallowed(:access_git) }
    end

    context 'user with expired password' do
      before do
        current_user.update!(password_expires_at: 2.minutes.ago)
      end

      it { is_expected.to be_disallowed(:access_git) }

      context 'when user is using ldap' do
        let(:current_user) { create(:omniauth_user, provider: 'ldap', password_expires_at: 2.minutes.ago) }

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

      it { is_expected.to be_disallowed(:read_instance_metadata) }
    end
  end

  describe 'slash commands' do
    context 'regular user' do
      it { is_expected.to be_allowed(:use_slash_commands) }
    end

    context 'when internal' do
      let(:current_user) { Users::Internal.ghost }

      it { is_expected.to be_disallowed(:use_slash_commands) }
    end

    context 'when blocked' do
      before do
        current_user.block
      end

      it { is_expected.to be_disallowed(:use_slash_commands) }
    end

    context 'when deactivated' do
      before do
        current_user.deactivate
      end

      it { is_expected.to be_disallowed(:use_slash_commands) }
    end

    describe 'inactive user' do
      before do
        stub_application_setting_enum('email_confirmation_setting', 'soft')
        current_user.update!(confirmed_at: nil)
      end

      it { is_expected.to be_disallowed(:use_slash_commands) }
    end

    context 'when access locked' do
      before do
        current_user.lock_access!
      end

      it { is_expected.to be_disallowed(:use_slash_commands) }
    end

    context 'project bot' do
      let(:current_user) { project_bot }

      it { is_expected.to be_allowed(:use_slash_commands) }
    end

    context 'service account' do
      let(:current_user) { service_account }

      it { is_expected.to be_allowed(:use_slash_commands) }
    end

    context 'migration bot' do
      let(:current_user) { migration_bot }

      it { is_expected.to be_disallowed(:use_slash_commands) }
    end

    context 'user blocked pending approval' do
      before do
        current_user.block_pending_approval
      end

      it { is_expected.to be_disallowed(:use_slash_commands) }
    end

    context 'user with expired password' do
      before do
        current_user.update!(password_expires_at: 2.minutes.ago)
      end

      it { is_expected.to be_disallowed(:use_slash_commands) }

      context 'when user is using ldap' do
        let(:current_user) { create(:omniauth_user, provider: 'ldap', password_expires_at: 2.minutes.ago) }

        it { is_expected.to be_allowed(:use_slash_commands) }
      end
    end
  end

  describe 'create_snippet' do
    context 'when anonymous' do
      let(:current_user) { nil }

      it { is_expected.to be_disallowed(:create_snippet) }
    end

    context 'regular user' do
      it { is_expected.to be_allowed(:create_snippet) }
    end

    context 'when external' do
      let(:current_user) { build(:user, :external) }

      it { is_expected.to be_disallowed(:create_snippet) }
    end
  end

  describe 'log in' do
    context 'project bot' do
      let(:current_user) { project_bot }

      it { is_expected.to be_disallowed(:log_in) }
    end

    context 'service account' do
      let(:current_user) { service_account }

      it { is_expected.to be_disallowed(:log_in) }
    end

    context 'migration bot' do
      let(:current_user) { migration_bot }

      it { is_expected.to be_disallowed(:log_in) }
    end

    context 'security bot' do
      let(:current_user) { security_bot }

      it { is_expected.to be_disallowed(:log_in) }
    end

    context 'llm bot' do
      let(:current_user) { llm_bot }

      it { is_expected.to be_disallowed(:log_in) }
    end

    context 'user blocked pending approval' do
      before do
        current_user.block_pending_approval
      end

      it { is_expected.to be_disallowed(:log_in) }
    end
  end

  describe 'create_instance_runner' do
    context 'admin' do
      let(:current_user) { admin_user }

      context 'when admin mode is enabled', :enable_admin_mode do
        it { is_expected.to be_allowed(:create_instance_runner) }
      end

      context 'when admin mode is disabled' do
        it { is_expected.to be_disallowed(:create_instance_runner) }
      end
    end

    context 'with project_bot' do
      let(:current_user) { project_bot }

      it { is_expected.to be_disallowed(:create_instance_runner) }
    end

    context 'with migration_bot' do
      let(:current_user) { migration_bot }

      it { is_expected.to be_disallowed(:create_instance_runner) }
    end

    context 'with security_bot' do
      let(:current_user) { security_bot }

      it { is_expected.to be_disallowed(:create_instance_runner) }
    end

    context 'with llm_bot' do
      let(:current_user) { llm_bot }

      it { is_expected.to be_disallowed(:create_instance_runners) }
    end

    context 'with regular user' do
      let(:current_user) { user }

      it { is_expected.to be_disallowed(:create_instance_runner) }
    end

    context 'with anonymous' do
      let(:current_user) { nil }

      it { is_expected.to be_disallowed(:create_instance_runner) }
    end
  end

  describe 'use_quick_actions' do
    HasUserType::BOT_USER_TYPES.each do |bot|
      context "with #{bot}" do
        let(:current_user) { public_send(bot) }

        if bot.in?(%w[alert_bot project_bot support_bot admin_bot service_account])
          it { is_expected.to be_allowed(:use_quick_actions) }
        else
          it { is_expected.to be_disallowed(:use_quick_actions) }
        end
      end
    end

    context 'with regular user' do
      let(:current_user) { user }

      it { is_expected.to be_allowed(:use_quick_actions) }
    end

    context 'with anonymous' do
      let(:current_user) { nil }

      it { is_expected.to be_disallowed(:use_quick_actions) }
    end
  end

  describe 'create_organization' do
    context 'with regular user' do
      let(:current_user) { user }

      it { is_expected.to be_allowed(:create_organization) }

      context 'when disallowed by admin' do
        before do
          stub_application_setting(can_create_organization: false)
        end

        it { is_expected.to be_disallowed(:create_organization) }
      end
    end

    context 'with anonymous' do
      let(:current_user) { nil }

      it { is_expected.to be_disallowed(:create_organizatinon) }
    end
  end

  describe 'admin pages' do
    context 'with regular user' do
      it { is_expected.to be_disallowed(:read_admin_cicd) }
    end

    context 'with an admin', :enable_admin_mode, :aggregate_failures do
      let(:current_user) { admin_user }
      let(:permissions) do
        [
          :read_admin_audit_log,
          :read_admin_background_jobs,
          :read_admin_background_migrations,
          :read_admin_cicd,
          :read_admin_health_check,
          :read_admin_metrics_dashboard,
          :read_admin_system_information
        ]
      end

      it { expect_allowed(*permissions) }
    end
  end
end
