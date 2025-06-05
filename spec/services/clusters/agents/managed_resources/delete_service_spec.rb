# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Agents::ManagedResources::DeleteService, feature_category: :deployment_management do
  let_it_be_with_reload(:managed_resource) { create(:managed_resource, status: :deleting) }

  describe '#execute' do
    let(:kas_client) { instance_double(Gitlab::Kas::Client) }

    subject(:execute) { described_class.new(managed_resource).execute }

    before do
      allow(Gitlab::Kas::Client).to receive(:new).and_return(kas_client)
    end

    shared_context 'with delete environment mocked' do
      before do
        allow(kas_client).to receive(:delete_environment).with(managed_resource: managed_resource)
          .and_return(kas_response)
      end
    end

    context 'when the managed resource is not in the correct initial state' do
      before do
        managed_resource.update!(status: :completed)
      end

      it 'does not delete resources' do
        expect(kas_client).not_to receive(:delete_environment)

        execute

        expect(managed_resource.status).to eq('completed')
      end
    end

    context 'when KAS returns an error' do
      include_context 'with delete environment mocked'

      let(:attempt_count) { 1 }

      let(:namespace) { managed_resource.tracked_objects.first }
      let(:namespace_error) do
        Gitlab::Agent::ManagedResources::Rpc::ObjectError.new(error: 'error message', object: namespace)
      end

      let(:namespace_error_message) do
        "Error deleting managed resources: core/v1/Namespace 'production' failed with message 'error message'"
      end

      let(:role_binding) { managed_resource.tracked_objects.second }
      let(:role_binding_error) do
        Gitlab::Agent::ManagedResources::Rpc::ObjectError.new(error: 'error message', object: role_binding)
      end

      let(:role_binding_error_message) do
        "Error deleting managed resources: rbac.authorization.k8s.io/v1/RoleBinding 'bind-ci-job-production' " \
          "in namespace 'production' failed with message 'error message'"
      end

      let(:kas_response) do
        Gitlab::Agent::ManagedResources::Rpc::DeleteEnvironmentResponse.new(
          errors: [namespace_error, role_binding_error],
          in_progress: []
        )
      end

      it 'queues a worker for the next deletion attempt' do
        expect(Clusters::Agents::ManagedResources::DeleteWorker).to receive(:perform_in)
          .with(described_class::POLLING_SCHEDULE.first, managed_resource.id, attempt_count)
          .and_call_original

        expect_next_instance_of(Gitlab::Kubernetes::Logger) do |logger|
          expect(logger).to receive(:error).with(
            message: namespace_error_message,
            agent_id: managed_resource.cluster_agent_id,
            environment_id: managed_resource.environment_id
          ).and_call_original

          expect(logger).to receive(:error).with(
            message: role_binding_error_message,
            agent_id: managed_resource.cluster_agent_id,
            environment_id: managed_resource.environment_id
          ).and_call_original
        end

        execute

        expect(managed_resource.status).to eq('deleting')
      end
    end

    context 'when all resources are deleted' do
      include_context 'with delete environment mocked'

      let(:kas_response) do
        Gitlab::Agent::ManagedResources::Rpc::DeleteEnvironmentResponse.new(
          errors: [],
          in_progress: []
        )
      end

      it 'sets the status to deleted' do
        execute

        expect(managed_resource.status).to eq('deleted')
        expect(managed_resource.tracked_objects).to be_empty
      end

      it 'emits deletion events for all deleted resources' do
        expect { execute }
          .to trigger_internal_events('delete_gvk_resource_for_managed_resource')
          .with(
            project: managed_resource.environment.project,
            category: 'InternalEventTracking',
            additional_properties: {
              label: 'core/v1/Namespace',
              property: managed_resource.environment.tier,
              value: managed_resource.environment_id
            }
          )
          .and trigger_internal_events('delete_gvk_resource_for_managed_resource')
          .with(
            project: managed_resource.environment.project,
            category: 'InternalEventTracking',
            additional_properties: {
              label: 'rbac.authorization.k8s.io/v1/RoleBinding',
              property: managed_resource.environment.tier,
              value: managed_resource.environment_id
            }
          )
      end
    end

    context 'when deletion is still in progress' do
      include_context 'with delete environment mocked'

      let(:attempt_count) { 1 }
      let(:in_progress_object) do
        {
          kind: 'Namespace',
          name: 'production',
          group: '',
          version: 'v1',
          namespace: ''
        }.stringify_keys
      end

      let(:kas_response) do
        Gitlab::Agent::ManagedResources::Rpc::DeleteEnvironmentResponse.new(
          errors: [],
          in_progress: [Gitlab::Agent::ManagedResources::Rpc::Object.new(**in_progress_object)]
        )
      end

      it 'queues a worker for the next deletion attempt' do
        expect(Clusters::Agents::ManagedResources::DeleteWorker).to receive(:perform_in)
          .with(described_class::POLLING_SCHEDULE.first, managed_resource.id, attempt_count)
          .and_call_original

        execute

        expect(managed_resource.status).to eq('deleting')
        expect(managed_resource.tracked_objects).to contain_exactly(in_progress_object)
      end

      it 'emits a deletion event for the deleted resource' do
        expect { execute }
          .to trigger_internal_events('delete_gvk_resource_for_managed_resource')
          .with(
            project: managed_resource.environment.project,
            category: 'InternalEventTracking',
            additional_properties: {
              label: 'rbac.authorization.k8s.io/v1/RoleBinding',
              property: managed_resource.environment.tier,
              value: managed_resource.environment_id
            }
          )
      end

      context 'when the attempt limit is reached' do
        let(:attempt_count) { described_class::POLLING_SCHEDULE.length }

        subject(:execute) { described_class.new(managed_resource, attempt_count: attempt_count).execute }

        it 'sets the status to delete_failed' do
          expect(Clusters::Agents::ManagedResources::DeleteWorker).not_to receive(:perform_in)

          expect_next_instance_of(Gitlab::Kubernetes::Logger) do |logger|
            expect(logger).to receive(:error).with(
              message: "Error deleting managed resources: timeout",
              agent_id: managed_resource.cluster_agent_id,
              environment_id: managed_resource.environment_id
            ).and_call_original
          end

          execute

          expect(managed_resource.status).to eq('delete_failed')
          expect(managed_resource.tracked_objects).to contain_exactly(in_progress_object)
        end
      end
    end
  end
end
