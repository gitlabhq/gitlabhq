# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::EnsurePreparedWorker, :sidekiq_inline, feature_category: :code_review_workflow do
  subject(:worker) { described_class.new }

  let_it_be(:merge_request_1, reload: true) { create(:merge_request, prepared_at: :nil) }
  let_it_be(:merge_request_2, reload: true) { create(:merge_request, prepared_at: Time.current) }
  let_it_be(:merge_request_3, reload: true) { create(:merge_request, prepared_at: :nil) }

  describe '#perform' do
    context 'when ensure_merge_requests_prepared is enabled' do
      it 'creates the expected NewMergeRequestWorkers of the unprepared merge requests' do
        expect(merge_request_1.prepared_at).to eq(nil)
        expect(merge_request_2.prepared_at).to eq(merge_request_2.prepared_at)
        expect(merge_request_3.prepared_at).to eq(nil)

        worker.perform

        expect(merge_request_1.reload.prepared_at).not_to eq(nil)
        expect(merge_request_2.reload.prepared_at).to eq(merge_request_2.prepared_at)
        expect(merge_request_3.reload.prepared_at).not_to eq(nil)
      end
    end

    context 'when ensure_merge_requests_prepared is disabled' do
      before do
        stub_feature_flags(ensure_merge_requests_prepared: false)
      end

      it 'does not prepare any merge requests' do
        expect(merge_request_1.prepared_at).to eq(nil)
        expect(merge_request_2.prepared_at).to eq(merge_request_2.prepared_at)
        expect(merge_request_3.prepared_at).to eq(nil)

        worker.perform

        expect(merge_request_1.prepared_at).to eq(nil)
        expect(merge_request_2.prepared_at).to eq(merge_request_2.prepared_at)
        expect(merge_request_3.prepared_at).to eq(nil)
      end
    end
  end

  it_behaves_like 'an idempotent worker' do
    it 'creates the expected NewMergeRequestWorkers of the unprepared merge requests' do
      expect(merge_request_1.prepared_at).to eq(nil)
      expect(merge_request_2.prepared_at).to eq(merge_request_2.prepared_at)
      expect(merge_request_3.prepared_at).to eq(nil)

      subject

      expect(merge_request_1.reload.prepared_at).not_to eq(nil)
      expect(merge_request_2.reload.prepared_at).to eq(merge_request_2.prepared_at)
      expect(merge_request_3.reload.prepared_at).not_to eq(nil)
    end
  end
end
