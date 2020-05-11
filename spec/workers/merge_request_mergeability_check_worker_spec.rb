# frozen_string_literal: true

require 'spec_helper'

describe MergeRequestMergeabilityCheckWorker do
  subject { described_class.new }

  describe '#perform' do
    context 'when merge request does not exist' do
      it 'does not execute MergeabilityCheckService' do
        expect(MergeRequests::MergeabilityCheckService).not_to receive(:new)

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
