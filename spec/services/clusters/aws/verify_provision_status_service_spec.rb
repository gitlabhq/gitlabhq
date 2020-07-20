# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Aws::VerifyProvisionStatusService do
  describe '#execute' do
    let(:provider) { create(:cluster_provider_aws) }

    let(:stack) { double(stack_status: stack_status, creation_time: creation_time) }
    let(:creation_time) { 1.minute.ago }

    subject { described_class.new.execute(provider) }

    before do
      allow(provider.api_client).to receive(:describe_stacks)
        .with(stack_name: provider.cluster.name)
        .and_return(double(stacks: [stack]))
    end

    shared_examples 'provision error' do |message|
      it "sets the status to :errored with an appropriate error message" do
        subject

        expect(provider).to be_errored
        expect(provider.status_reason).to include(message)
      end
    end

    context 'stack creation is still in progress' do
      let(:stack_status) { 'CREATE_IN_PROGRESS' }
      let(:verify_service) { double(execute: true) }

      it 'schedules a worker to check again later' do
        expect(WaitForClusterCreationWorker).to receive(:perform_in)
          .with(described_class::POLL_INTERVAL, provider.cluster_id)

        subject
      end

      context 'stack creation is taking too long' do
        let(:creation_time) { 1.hour.ago }

        include_examples 'provision error', 'Kubernetes cluster creation time exceeds timeout'
      end
    end

    context 'stack creation is complete' do
      let(:stack_status) { 'CREATE_COMPLETE' }
      let(:finalize_service) { double(execute: true) }

      it 'finalizes creation' do
        expect(Clusters::Aws::FinalizeCreationService).to receive(:new).and_return(finalize_service)
        expect(finalize_service).to receive(:execute).with(provider).once

        subject
      end
    end

    context 'stack creation failed' do
      let(:stack_status) { 'CREATE_FAILED' }

      include_examples 'provision error', 'Unexpected status'
    end

    context 'error communicating with CloudFormation API' do
      let(:stack_status) { 'CREATE_IN_PROGRESS' }

      before do
        allow(provider.api_client).to receive(:describe_stacks)
          .and_raise(Aws::CloudFormation::Errors::ServiceError.new(double, 'Error message'))
      end

      include_examples 'provision error', 'Amazon CloudFormation request failed'
    end
  end
end
