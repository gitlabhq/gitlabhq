# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::ProjectNamespacePolicy, feature_category: :groups_and_projects do
  include ExternalAuthorizationServiceHelpers
  include AdminModeHelper

  let_it_be(:public_project) { create(:project, :public) }
  let_it_be(:private_project) { create(:project, :private) }

  subject { described_class.new(current_user, namespace) }

  it_behaves_like 'checks timelog categories permissions' do
    let(:project) { create(:project) }
    let(:namespace) { project.project_namespace }
    let(:users_container) { project }
  end

  context 'with read_namespace permissions' do
    let(:project) { public_project }
    let(:owner) { project.creator }
    let(:developer) { create(:user) }
    let(:admin) { create(:admin) }
    let(:namespace) { project.project_namespace }

    before do
      project.add_developer(developer)
    end

    it 'allows access when a user has read access to the project' do
      expect(described_class.new(owner, project.project_namespace)).to be_allowed(:read_project, :read_namespace)
      expect(described_class.new(developer, project.project_namespace)).to be_allowed(:read_project, :read_namespace)
      expect(described_class.new(admin, project.project_namespace)).to be_allowed(:read_project, :read_namespace)
    end

    it 'never checks the external service' do
      expect(::Gitlab::ExternalAuthorization).not_to receive(:access_allowed?)

      expect(described_class.new(owner, namespace)).to be_allowed(:read_project, :read_namespace)
    end

    context 'with an external authorization service' do
      before do
        enable_external_authorization_service_check
      end

      it 'allows access when the external service allows it' do
        external_service_allow_access(owner, project)
        external_service_allow_access(developer, project)

        expect(described_class.new(owner, namespace)).to be_allowed(:read_project, :read_namespace)
        expect(described_class.new(developer, namespace)).to be_allowed(:read_project, :read_namespace)
      end

      context 'with an admin' do
        context 'when admin mode is enabled', :enable_admin_mode do
          it 'does not check the external service and allows access' do
            expect(::Gitlab::ExternalAuthorization).not_to receive(:access_allowed?)

            expect(described_class.new(admin, namespace)).to be_allowed(:read_project, :read_namespace)
          end
        end

        context 'when admin mode is disabled' do
          it 'checks the external service and allows access' do
            external_service_allow_access(admin, project)

            expect(::Gitlab::ExternalAuthorization).to receive(:access_allowed?)

            expect(described_class.new(admin, namespace)).to be_allowed(:read_project, :read_namespace)
          end
        end
      end

      it 'prevents all but seeing a public project in a list when access is denied' do
        [developer, owner, build(:user), nil].each do |user|
          external_service_deny_access(user, project)
          policy = described_class.new(user, namespace)

          expect(policy).not_to be_allowed(:read_project, :read_namespace)
        end
      end

      it 'passes the full path to external authorization for logging purposes' do
        expect(::Gitlab::ExternalAuthorization)
          .to receive(:access_allowed?).with(owner, 'default_label', project.full_path).and_call_original

        described_class.new(owner, namespace).allowed?(:read_project, :read_namespace)
      end
    end

    context 'with support bot user' do
      let(:current_user) { Users::Internal.support_bot }

      context 'with service desk disabled' do
        it { expect(described_class.new(current_user, namespace)).not_to be_allowed(:read_project, :read_namespace) }
      end
    end

    context 'with deploy key access actor' do
      context 'when project is private' do
        let(:project) { private_project }
        let!(:deploy_key) { create(:deploy_key, user: owner) }

        subject { described_class.new(deploy_key, project.project_namespace) }

        context 'when a read deploy key is enabled in the project' do
          let!(:deploy_keys_project) { create(:deploy_keys_project, project: project, deploy_key: deploy_key) }

          it { is_expected.to be_disallowed(:read_project, :read_namespace) }
        end

        context 'when a write deploy key is enabled in the project' do
          let!(:deploy_keys_project) do
            create(:deploy_keys_project, :write_access, project: project, deploy_key: deploy_key)
          end

          it { is_expected.to be_disallowed(:read_project, :read_namespace) }
        end

        context 'when the deploy key is not enabled in the project' do
          it { is_expected.to be_disallowed(:read_project, :read_namespace) }
        end
      end
    end

    describe 'when project is created and owned by a banned user' do
      let_it_be(:project) { create(:project, :public) }

      let(:current_user) { developer }

      before do
        allow(project).to receive(:created_and_owned_by_banned_user?).and_return(true)
      end

      it { expect_disallowed(:read_project, :read_namespace) }

      context 'when current user is an admin', :enable_admin_mode do
        let(:current_user) { admin }

        it { expect_allowed(:read_project, :read_namespace) }
      end

      context 'when hide_projects_of_banned_users FF is disabled' do
        before do
          stub_feature_flags(hide_projects_of_banned_users: false)
        end

        it { expect_allowed(:read_project, :read_namespace) }
      end
    end
  end
end
