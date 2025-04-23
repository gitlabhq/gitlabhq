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
      let(:attempt_count) { 1 }
      let(:kas_response) do
        Gitlab::Agent::ManagedResources::Rpc::DeleteEnvironmentResponse.new(
          errors: [Gitlab::Agent::ManagedResources::Rpc::ObjectError.new(error: 'error message', object: {})],
          in_progress: []
        )
      end

      before do
        allow(kas_client).to receive(:delete_environment).with(managed_resource: managed_resource)
          .and_return(kas_response)
      end

      it 'queues a worker for the next deletion attempt' do
        expect(Clusters::Agents::ManagedResources::DeleteWorker).to receive(:perform_in)
          .with(described_class::POLLING_SCHEDULE.first, managed_resource.id, attempt_count)
          .and_call_original

        execute

        expect(managed_resource.status).to eq('deleting')
      end
    end

    context 'when all resources are deleted' do
      let(:kas_response) do
        Gitlab::Agent::ManagedResources::Rpc::DeleteEnvironmentResponse.new(
          errors: [],
          in_progress: []
        )
      end

      it 'sets the status to deleted' do
        expect(kas_client).to receive(:delete_environment).with(managed_resource: managed_resource)
          .and_return(kas_response)

        execute

        expect(managed_resource.status).to eq('deleted')
        expect(managed_resource.tracked_objects).to be_empty
      end
    end

    context 'when deletion is still in progress' do
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
        expect(kas_client).to receive(:delete_environment).with(managed_resource: managed_resource)
          .and_return(kas_response)

        expect(Clusters::Agents::ManagedResources::DeleteWorker).to receive(:perform_in)
          .with(described_class::POLLING_SCHEDULE.first, managed_resource.id, attempt_count)
          .and_call_original

        execute

        expect(managed_resource.status).to eq('deleting')
        expect(managed_resource.tracked_objects).to contain_exactly(in_progress_object)
      end

      context 'when the attempt limit is reached' do
        let(:attempt_count) { described_class::POLLING_SCHEDULE.length }

        subject(:execute) { described_class.new(managed_resource, attempt_count: attempt_count).execute }

        it 'sets the status to delete_failed' do
          expect(kas_client).to receive(:delete_environment).with(managed_resource: managed_resource)
            .and_return(kas_response)

          expect(Clusters::Agents::ManagedResources::DeleteWorker).not_to receive(:perform_in)

          execute

          expect(managed_resource.status).to eq('delete_failed')
          expect(managed_resource.tracked_objects).to contain_exactly(in_progress_object)
        end
      end
    end
  end
end
