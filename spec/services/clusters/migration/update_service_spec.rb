# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Migration::UpdateService, feature_category: :deployment_management do
  include Gitlab::Routing

  shared_examples 'cluster migration update service' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group, maintainers: [user]) }
    let_it_be(:project) { create(:project, group: group) }
    let_it_be(:issue_project) { create(:project, :public) }
    let_it_be(:issue) { create(:issue, project: issue_project) }
    let_it_be(:cluster_name) { '-Legacy cluster with invalid name #123-' }
    let_it_be(:agent_name) { 'new-agent' }
    let_it_be(:issue_url) { project_issue_url(issue_project, issue) }

    let(:service) do
      described_class.new(
        cluster,
        clusterable: clusterable,
        current_user: current_user,
        issue_url: issue_url
      )
    end

    subject(:execute_service) { service.execute }

    context 'when the feature flag is disabled' do
      before do
        stub_feature_flags(cluster_agent_migrations: false)
      end

      it 'returns an error' do
        expect(execute_service).to be_error
        expect(execute_service.message).to eq('Feature disabled')
      end
    end

    context 'when the user does not have permission' do
      before do
        allow(current_user).to receive(:can?).with(:admin_cluster, cluster).and_return(false)
      end

      it 'returns an error' do
        expect(execute_service).to be_error
        expect(execute_service.message).to eq('Unauthorized')
      end
    end

    context 'when no agent migration exists' do
      it 'returns an error' do
        expect(execute_service).to be_error
        expect(execute_service.message).to eq('No migration found')
      end
    end

    context 'with an existing migration' do
      let!(:migration) { create(:cluster_agent_migration, cluster: cluster, agent_name: agent_name) }

      context 'when issue URL is invalid' do
        let(:invalid_url) { 'invalid-url' }

        it 'returns an error' do
          invalid_service = described_class.new(
            cluster,
            clusterable: clusterable,
            current_user: current_user,
            issue_url: invalid_url
          )

          result = invalid_service.execute
          expect(result).to be_error
          expect(result.message).to eq('Invalid issue URL')
        end
      end

      context 'when migration update succeeds' do
        it 'updates the migration record with the issue' do
          service = described_class.new(
            cluster,
            clusterable: clusterable,
            current_user: current_user,
            issue_url: issue_url
          )

          result = service.execute
          expect(result).to be_success

          migration.reload
          expect(migration.issue).to eq(issue)
        end
      end

      context 'when migration update fails' do
        before do
          error_messages = ['Error 1', 'Error 2']
          errors = instance_double(ActiveModel::Errors, full_messages: error_messages)

          allow(migration).to receive_messages(save: false, errors: errors)
        end

        it 'logs detailed error messages' do
          expect(Gitlab::AppLogger).to receive(:error).with("Migration issue update failed: Error 1, Error 2")

          service.execute
        end

        it 'returns an error response with the generic error message' do
          result = service.execute

          expect(result).to be_error
          expect(result.message).to eq("Something went wrong")
        end
      end
    end
  end

  before do
    project.add_maintainer(current_user)
    issue_project.add_reporter(current_user)
  end

  describe 'with a project cluster' do
    let(:cluster) { create(:cluster, :project, provider_type: :user, name: cluster_name, projects: [project]) }
    let(:clusterable) { ProjectClusterablePresenter.new(project) }
    let(:current_user) { user }

    include_examples 'cluster migration update service', :project
  end

  describe 'with a group cluster' do
    let(:cluster) { create(:cluster, :group, provider_type: :user, name: cluster_name, groups: [group]) }
    let(:clusterable) { GroupClusterablePresenter.new(group) }
    let(:current_user) { user }

    include_examples 'cluster migration update service', :group
  end

  describe 'with an instance cluster', :enable_admin_mode do
    let(:cluster) { create(:cluster, :instance, provider_type: :user, name: cluster_name) }
    let(:clusterable) { InstanceClusterablePresenter.new(Clusters::Instance.new) }
    let(:current_user) { create(:admin) }

    include_examples 'cluster migration update service', :instance
  end
end
