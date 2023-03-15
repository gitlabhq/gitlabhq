# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ScheduleMigrateExternalDiffsWorker, feature_category: :code_review_workflow do
  include ExclusiveLeaseHelpers

  let(:worker) { described_class.new }

  describe '#perform' do
    it 'triggers a scan for diffs to migrate' do
      expect(MergeRequests::MigrateExternalDiffsService).to receive(:enqueue!)

      worker.perform
    end

    it 'will not run if the lease is already taken' do
      stub_exclusive_lease_taken('schedule_migrate_external_diffs_worker', timeout: 2.hours)

      expect(MergeRequests::MigrateExternalDiffsService).not_to receive(:enqueue!)

      worker.perform
    end
  end
end
