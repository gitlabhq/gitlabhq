# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ScheduleMergeRequestCleanupRefsWorker do
  subject(:worker) { described_class.new }

  describe '#perform' do
    it 'does nothing if the database is read-only' do
      allow(Gitlab::Database).to receive(:read_only?).and_return(true)
      expect(MergeRequestCleanupRefsWorker).not_to receive(:perform_with_capacity)

      worker.perform
    end

    context 'when merge_request_refs_cleanup flag is disabled' do
      before do
        stub_feature_flags(merge_request_refs_cleanup: false)
      end

      it 'does not schedule any merge request clean ups' do
        expect(MergeRequestCleanupRefsWorker).not_to receive(:perform_with_capacity)

        worker.perform
      end
    end

    include_examples 'an idempotent worker' do
      it 'schedules MergeRequestCleanupRefsWorker to be performed with capacity' do
        expect(MergeRequestCleanupRefsWorker).to receive(:perform_with_capacity).twice

        subject
      end
    end
  end
end
