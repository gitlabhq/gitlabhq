# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ScheduleMergeRequestCleanupRefsWorker do
  subject(:worker) { described_class.new }

  describe '#perform' do
    before do
      allow(MergeRequest::CleanupSchedule)
        .to receive(:scheduled_merge_request_ids)
        .with(described_class::LIMIT)
        .and_return([1, 2, 3, 4])
    end

    it 'does nothing if the database is read-only' do
      allow(Gitlab::Database).to receive(:read_only?).and_return(true)
      expect(MergeRequestCleanupRefsWorker).not_to receive(:bulk_perform_in)

      worker.perform
    end

    context 'when merge_request_refs_cleanup flag is disabled' do
      before do
        stub_feature_flags(merge_request_refs_cleanup: false)
      end

      it 'does not schedule any merge request clean ups' do
        expect(MergeRequestCleanupRefsWorker).not_to receive(:bulk_perform_in)

        worker.perform
      end
    end

    include_examples 'an idempotent worker' do
      it 'schedules MergeRequestCleanupRefsWorker to be performed by batch' do
        expect(MergeRequestCleanupRefsWorker)
          .to receive(:bulk_perform_in)
          .with(
            described_class::DELAY,
            [[1], [2], [3], [4]],
            batch_size: described_class::BATCH_SIZE
          )

        expect(worker).to receive(:log_extra_metadata_on_done).with(:merge_requests_count, 4)

        worker.perform
      end
    end
  end
end
