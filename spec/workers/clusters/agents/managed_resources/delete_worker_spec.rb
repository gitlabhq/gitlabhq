# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Agents::ManagedResources::DeleteWorker, feature_category: :deployment_management do
  let_it_be(:managed_resource) { create(:managed_resource) }

  it_behaves_like 'an idempotent worker' do
    let(:job_args) { managed_resource.id }
  end

  describe '#perform' do
    let(:managed_resource_id) { managed_resource.id }

    subject(:perform) { described_class.new.perform(managed_resource_id) }

    it 'calls the deletion service' do
      expect_next_instance_of(Clusters::Agents::ManagedResources::DeleteService, managed_resource,
        attempt_count: nil) do |service|
        expect(service).to receive(:execute).once
      end

      perform
    end

    context 'when an attempt number is provided' do
      let(:attempt) { 123 }

      subject(:perform) { described_class.new.perform(managed_resource_id, attempt) }

      it 'calls the deletion service with the supplied attempt number' do
        expect_next_instance_of(Clusters::Agents::ManagedResources::DeleteService, managed_resource,
          attempt_count: attempt) do |service|
          expect(service).to receive(:execute).once
        end

        perform
      end
    end

    context 'when the managed resource record no longer exists' do
      let(:managed_resource_id) { non_existing_record_id }

      it 'completes without raising an error' do
        expect { perform }.not_to raise_error
      end
    end
  end
end
