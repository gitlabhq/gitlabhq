# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::UserNamespacePolicy, feature_category: :groups_and_projects do
  let_it_be(:user) { create(:user) }
  let_it_be(:owner) { create(:user) }
  let_it_be(:admin) { create(:admin) }
  let_it_be(:namespace) { create(:user_namespace, owner: owner) }

  let(:owner_permissions) { [:owner_access, :create_projects, :admin_runner, :admin_namespace, :read_namespace, :read_namespace_via_membership, :read_statistics, :transfer_projects, :admin_package, :read_billing, :edit_billing, :import_projects] }

  subject { described_class.new(current_user, namespace) }

  context 'with no user' do
    let(:current_user) { nil }

    it { is_expected.to be_banned }
  end

  context 'regular user' do
    let(:current_user) { user }

    it { is_expected.to be_disallowed(*owner_permissions) }
  end

  context 'owner' do
    let(:current_user) { owner }

    it { is_expected.to be_allowed(*owner_permissions) }

    context 'user who has exceeded project limit' do
      let(:owner) { create(:user, projects_limit: 0) }

      it { is_expected.to be_disallowed(:create_projects) }
      it { is_expected.to be_disallowed(:transfer_projects) }
      it { is_expected.to be_disallowed(:import_projects) }
    end

    context 'bot user' do
      let(:owner) { create(:user, :project_bot) }

      it { is_expected.to be_disallowed(:create_projects) }
      it { is_expected.to be_disallowed(:transfer_projects) }
      it { is_expected.to be_disallowed(:import_projects) }
    end
  end

  context 'admin' do
    let(:current_user) { admin }

    context 'when admin mode is enabled', :enable_admin_mode do
      it { is_expected.to be_allowed(*owner_permissions) }
    end

    context 'when admin mode is disabled' do
      it { is_expected.to be_disallowed(*owner_permissions) }
    end
  end

  describe 'create_jira_connect_subscription', feature_category: :integrations do
    context 'admin' do
      let(:current_user) { build_stubbed(:admin) }

      context 'when admin mode enabled', :enable_admin_mode do
        it { is_expected.to be_allowed(:create_jira_connect_subscription) }
      end

      context 'when admin mode disabled' do
        it { is_expected.to be_disallowed(:create_jira_connect_subscription) }
      end
    end

    context 'owner' do
      let(:current_user) { owner }

      it { is_expected.to be_allowed(:create_jira_connect_subscription) }
    end

    context 'other user' do
      let(:current_user) { build_stubbed(:user) }

      it { is_expected.to be_disallowed(:create_jira_connect_subscription) }
    end
  end

  describe 'create projects' do
    using RSpec::Parameterized::TableSyntax

    let(:current_user) { owner }

    context 'when user can create projects' do
      before do
        allow(current_user).to receive(:can_create_project?).and_return(true)
      end

      it { is_expected.to be_allowed(:create_projects) }
    end

    context 'when user cannot create projects' do
      before do
        allow(current_user).to receive(:can_create_project?).and_return(false)
      end

      it { is_expected.to be_disallowed(:create_projects) }
    end
  end

  describe 'import projects', feature_category: :importers do
    context 'when user can import projects' do
      let(:current_user) { owner }

      before do
        allow(current_user).to receive(:can_import_project?).and_return(true)
      end

      it { is_expected.to be_allowed(:import_projects) }
    end

    context 'when user cannot create projects' do
      let(:current_user) { user }

      before do
        allow(current_user).to receive(:can_import_project?).and_return(false)
      end

      it { is_expected.to be_disallowed(:import_projects) }
    end
  end
end
