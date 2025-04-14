# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Migration::CreateService, feature_category: :deployment_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, maintainers: [user]) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:configuration_project) { project }
  let_it_be(:cluster_name) { '-Legacy cluster with invalid name #123-' }
  let_it_be(:agent_name) { 'new-agent' }

  let(:service) do
    described_class.new(
      cluster,
      current_user: user,
      configuration_project_id: configuration_project.id,
      agent_name: agent_name
    )
  end

  subject(:response) { service.execute }

  shared_examples 'migrating a legacy cluster to use the agent' do
    context 'when the cluster_agent_migrations feature flag is disabled' do
      before do
        stub_feature_flags(cluster_agent_migrations: false)
      end

      it 'returns an error' do
        expect(Clusters::Agents::CreateService).not_to receive(:new)

        expect(response).to be_error
        expect(response.message).to eq('Feature disabled')
      end
    end

    context 'when the user does not have permission' do
      before do
        allow(user).to receive(:can?).with(:admin_cluster, cluster).and_return(false)
      end

      it 'returns an error' do
        expect(Clusters::Agents::CreateService).not_to receive(:new)

        expect(response).to be_error
        expect(response.message).to eq('Unauthorized')
      end
    end

    context 'when agent creation fails' do
      before do
        allow_next_instance_of(Clusters::Agents::CreateService) do |service|
          allow(service).to receive(:execute).and_return(ServiceResponse.error(message: 'Agent error message'))
        end
      end

      it 'returns an error' do
        expect(Clusters::AgentTokens::CreateService).not_to receive(:new)

        expect { response }.not_to change { Clusters::AgentMigration.count }
        expect(response).to be_error
        expect(response.message).to eq('Agent error message')
      end
    end

    context 'when token creation fails' do
      before do
        allow_next_instance_of(Clusters::AgentTokens::CreateService) do |service|
          allow(service).to receive(:execute).and_return(ServiceResponse.error(message: 'Token error message'))
        end
      end

      it 'returns an error' do
        expect { response }.not_to change { Clusters::AgentMigration.count }
        expect(response).to be_error
        expect(response.message).to eq('Token error message')
      end
    end

    context 'when migration creation fails' do
      before do
        create(:cluster_agent_migration, cluster: cluster, agent_name: 'existing-agent')
      end

      it 'returns an error' do
        expect { response }.not_to change { Clusters::AgentMigration.count }
        expect(response).to be_error
        expect(response.message).to contain_exactly('Cluster has already been taken')
      end
    end

    it 'creates an agent, token and migration record' do
      expect { response }.to change { Clusters::Agent.count }.by(1)
        .and change { Clusters::AgentToken.count }.by(1)
        .and change { Clusters::AgentMigration.count }.by(1)

      expect(response).to be_success

      migration = Clusters::AgentMigration.last
      expect(migration.cluster).to eq(cluster)
      expect(migration.project).to eq(project)

      agent = migration.agent
      expect(agent.name).to eq(agent_name)
      expect(agent.project).to eq(project)
      expect(agent.created_by_user).to eq(user)
      expect(agent.agent_tokens.count).to eq(1)

      token = agent.agent_tokens.first
      expect(token.name).to eq(agent_name)
      expect(token.created_by_user).to eq(user)
    end

    it 'schedules a worker to install the agent into the cluster' do
      allow(Clusters::Migration::InstallAgentWorker).to receive(:perform_async).and_call_original

      expect(response).to be_success

      migration = Clusters::AgentMigration.last
      expect(Clusters::Migration::InstallAgentWorker).to have_received(:perform_async).with(migration.id).once
    end
  end

  context 'with a project cluster' do
    let_it_be(:cluster) { create(:cluster, :project, provider_type: :user, name: cluster_name, projects: [project]) }

    include_examples 'migrating a legacy cluster to use the agent'

    context 'when the supplied configuration project belongs to a different top level group' do
      let_it_be(:configuration_project) { create(:project, maintainers: [user]) }

      it 'returns an error' do
        expect(Clusters::Agents::CreateService).not_to receive(:new)

        expect(response).to be_error
        expect(response.message).to eq('Invalid configuration project')
      end
    end
  end

  context 'with a group cluster' do
    let_it_be(:cluster) { create(:cluster, :group, provider_type: :user, name: cluster_name, groups: [group]) }

    include_examples 'migrating a legacy cluster to use the agent'

    context 'when the supplied configuration project belongs to a different top level group' do
      let_it_be(:configuration_project) { create(:project, maintainers: [user]) }

      it 'returns an error' do
        expect(Clusters::Agents::CreateService).not_to receive(:new)

        expect(response).to be_error
        expect(response.message).to eq('Invalid configuration project')
      end
    end
  end

  context 'with an instance cluster', :enable_admin_mode do
    let_it_be(:cluster) { create(:cluster, :instance, provider_type: :user, name: cluster_name) }

    before do
      user.update!(admin: true)
    end

    include_examples 'migrating a legacy cluster to use the agent'
  end
end
