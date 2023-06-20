# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::MergeabilityCheckBatchService, feature_category: :code_review_workflow do
  describe '#execute' do
    subject { described_class.new(merge_requests, user).execute }

    let(:merge_requests) { [] }
    let_it_be(:user) { create(:user) }

    context 'when merge_requests are not empty' do
      let_it_be(:merge_request_1) { create(:merge_request) }
      let_it_be(:merge_request_2) { create(:merge_request) }
      let_it_be(:merge_requests) { [merge_request_1, merge_request_2] }

      it 'triggers batch mergeability checks' do
        expect(MergeRequests::MergeabilityCheckBatchWorker).to receive(:perform_async)
          .with([merge_request_1.id, merge_request_2.id], user.id)

        subject
      end

      context 'when user is nil' do
        let(:user) { nil }

        it 'trigger mergeability checks with nil user_id' do
          expect(MergeRequests::MergeabilityCheckBatchWorker).to receive(:perform_async)
            .with([merge_request_1.id, merge_request_2.id], nil)

          subject
        end
      end
    end

    context 'when merge_requests is empty' do
      let(:merge_requests) { MergeRequest.none }

      it 'does not trigger mergeability checks' do
        expect(MergeRequests::MergeabilityCheckBatchWorker).not_to receive(:perform_async)

        subject
      end
    end
  end
end
