# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::MergeabilityCheckBatchWorker, feature_category: :code_review_workflow do
  subject { described_class.new }

  describe '#perform' do
    context 'when some merge_requests do not exist' do
      it 'ignores unknown merge request ids' do
        expect(MergeRequests::MergeabilityCheckService).not_to receive(:new)

        expect(Sidekiq.logger).not_to receive(:error)

        subject.perform([1234, 5678])
      end
    end

    context 'when some merge_requests needs mergeability checks' do
      let(:merge_request_1) { create(:merge_request, merge_status: :unchecked) }
      let(:merge_request_2) { create(:merge_request, merge_status: :cannot_be_merged_rechecking) }
      let(:merge_request_3) { create(:merge_request, merge_status: :can_be_merged) }

      it 'executes MergeabilityCheckService on merge requests that needs to be checked' do
        expect_next_instance_of(MergeRequests::MergeabilityCheckService, merge_request_1) do |service|
          expect(service).to receive(:execute).and_return(ServiceResponse.success)
        end
        expect_next_instance_of(MergeRequests::MergeabilityCheckService, merge_request_2) do |service|
          expect(service).to receive(:execute).and_return(ServiceResponse.success)
        end
        expect(MergeRequests::MergeabilityCheckService).not_to receive(:new).with(merge_request_3.id)
        expect(MergeRequests::MergeabilityCheckService).not_to receive(:new).with(1234)

        subject.perform([merge_request_1.id, merge_request_2.id, merge_request_3.id, 1234])
      end

      it 'structurally logs a failed mergeability check' do
        expect_next_instance_of(MergeRequests::MergeabilityCheckService, merge_request_1) do |service|
          expect(service).to receive(:execute).and_return(ServiceResponse.error(message: "solar flares"))
        end

        expect(Sidekiq.logger).to receive(:error).once
          .with(
            merge_request_id: merge_request_1.id,
            worker: described_class.to_s,
            message: 'Failed to check mergeability of merge request: solar flares')

        subject.perform([merge_request_1.id])
      end
    end

    it_behaves_like 'an idempotent worker' do
      let(:merge_request) { create(:merge_request) }
      let(:job_args) { [merge_request.id] }

      it 'is mergeable' do
        subject

        expect(merge_request).to be_mergeable
      end
    end
  end
end
