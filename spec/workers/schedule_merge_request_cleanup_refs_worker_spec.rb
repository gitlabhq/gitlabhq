# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ScheduleMergeRequestCleanupRefsWorker, feature_category: :code_review_workflow do
  subject(:worker) { described_class.new }

  describe '#perform' do
    it 'does nothing if the database is read-only' do
      allow(Gitlab::Database).to receive(:read_only?).and_return(true)
      expect(MergeRequestCleanupRefsWorker).not_to receive(:perform_with_capacity)

      worker.perform
    end

    it 'retries stuck cleanup schedules' do
      expect(MergeRequest::CleanupSchedule).to receive(:stuck_retry!)

      worker.perform
    end

    it_behaves_like 'an idempotent worker' do
      it 'schedules MergeRequestCleanupRefsWorker to be performed with capacity' do
        expect(MergeRequestCleanupRefsWorker).to receive(:perform_with_capacity).twice

        subject
      end
    end
  end
end
