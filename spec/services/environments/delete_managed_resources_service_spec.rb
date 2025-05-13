# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Environments::DeleteManagedResourcesService, feature_category: :deployment_management do
  let_it_be(:project) { create(:project) }
  let(:user) { create(:user, developer_of: project) }
  let(:environment) { create(:environment, :stopped, project: project) }
  let_it_be(:agent) { create(:cluster_agent, project: project) }
  let_it_be(:build) { create(:ci_build, project: project) }

  let!(:managed_resource) do
    create(:managed_resource, :completed, project: project, environment: environment, cluster_agent: agent,
      build: build)
  end

  before do
    allow_next_found_instance_of(Clusters::Agent) do |agent|
      allow(agent).to receive(:resource_management_enabled?).and_return(true)
    end
  end

  describe '#execute' do
    subject(:execute) { described_class.new(environment, current_user: user).execute }

    it 'sets the status to :deleting, queues the deletion worker' do
      expect(Clusters::Agents::ManagedResources::DeleteWorker).to receive(:perform_async)
        .with(managed_resource.id).once.and_call_original

      expect(execute.status).to eq(:success)
      expect(managed_resource.reload.status).to eq('deleting')
    end

    it 'emits an event and increment metrics' do
      expect { execute }
        .to trigger_internal_events('delete_environment_for_managed_resource')
        .with(
          user: user,
          project: project,
          category: 'InternalEventTracking',
          additional_properties: {
            label: project.namespace.actual_plan_name,
            property: environment.tier,
            value: environment.id
          })
        .and increment_usage_metrics(
          'redis_hll_counters.count_distinct_user_id_from_delete_environment_for_managed_resource_monthly',
          'redis_hll_counters.count_distinct_user_id_from_delete_environment_for_managed_resource_weekly',
          'redis_hll_counters.count_distinct_value_from_delete_environment_for_managed_resource_monthly',
          'redis_hll_counters.count_distinct_value_from_delete_environment_for_managed_resource_weekly')
    end

    shared_examples 'resources can not be deleted' do
      it 'does not attempt to delete resources' do
        expect(Clusters::Agents::ManagedResources::DeleteWorker).not_to receive(:perform_async)
        expect(execute).to be_nil
      end
    end

    context 'when the environment is not stopped' do
      before do
        environment.update!(state: :available)
      end

      it_behaves_like 'resources can not be deleted'
    end

    context 'when there is no associated managed resource' do
      before do
        managed_resource.destroy!
      end

      it_behaves_like 'resources can not be deleted'
    end

    context 'when the managed resource is not in the correct state' do
      before do
        managed_resource.update!(status: :failed)
      end

      it_behaves_like 'resources can not be deleted'
    end

    context 'when resource management is disabled' do
      before do
        allow_next_found_instance_of(Clusters::Agent) do |agent|
          allow(agent).to receive(:resource_management_enabled?).and_return(false)
        end
      end

      it_behaves_like 'resources can not be deleted'
    end

    context 'when the deletion strategy is not on_stop' do
      before do
        managed_resource.update!(deletion_strategy: :never)
      end

      it_behaves_like 'resources can not be deleted'
    end
  end
end
