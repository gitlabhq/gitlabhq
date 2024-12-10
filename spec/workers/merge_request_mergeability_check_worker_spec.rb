# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequestMergeabilityCheckWorker, feature_category: :code_review_workflow do
  subject { described_class.new }

  describe '#perform' do
    context 'when merge request does not exist' do
      it 'does not execute MergeabilityCheckService' do
        expect(MergeRequests::MergeabilityCheckService).not_to receive(:new)

        expect(Sidekiq.logger).to receive(:error).once
          .with(
            merge_request_id: 1,
            worker: "MergeRequestMergeabilityCheckWorker",
            message: 'Failed to find merge request')

        subject.perform(1)
      end
    end

    context 'when merge request exists' do
      let(:merge_request) { create(:merge_request) }

      it 'executes MergeabilityCheckService' do
        expect_next_instance_of(MergeRequests::MergeabilityCheckService, merge_request) do |service|
          expect(service).to receive(:execute).and_return(double(error?: false))
        end

        subject.perform(merge_request.id)
      end

      it 'structurally logs a failed mergeability check' do
        expect_next_instance_of(MergeRequests::MergeabilityCheckService, merge_request) do |service|
          expect(service).to receive(:execute).and_return(double(error?: true, message: "solar flares"))
        end

        expect(Sidekiq.logger).to receive(:error).once
          .with(
            'correlation_id' => an_instance_of(String),
            merge_request_id: merge_request.id,
            worker: "MergeRequestMergeabilityCheckWorker",
            message: 'Failed to check mergeability of merge request: solar flares')

        subject.perform(merge_request.id)
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
