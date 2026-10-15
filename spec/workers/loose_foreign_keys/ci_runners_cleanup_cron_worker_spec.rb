# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LooseForeignKeys::CiRunnersCleanupCronWorker, feature_category: :database do
  let(:worker) { described_class.new }

  describe '#perform' do
    it 'processes runner deletions on the CI connection with the default limits', :aggregate_failures do
      stats = { over_limit: false, delete_count: 0 }
      tracker = an_instance_of(LooseForeignKeys::ModificationTracker)

      expect(LooseForeignKeys::ModificationTracker).to receive(:new).and_call_original
      expect(LooseForeignKeys::ProcessDeletedRecordsService).to receive(:new).with(
        connection: Ci::ApplicationRecord.connection,
        modification_tracker: tracker,
        logger: Sidekiq.logger,
        worker_class: described_class,
        record_store: Gitlab::LooseForeignKeys::DeletedRecordStore
      ).and_return(instance_double(LooseForeignKeys::ProcessDeletedRecordsService, execute: stats))
      expect(worker).to receive(:log_extra_metadata_on_done).with(:stats, stats)

      worker.perform
    end

    it 'uses a class-specific lock for longer than the tracker runtime' do
      expect(worker).to receive(:in_lock).with(
        described_class.name.underscore,
        ttl: LooseForeignKeys::ModificationTracker.new.max_runtime + 10.seconds,
        retries: 0
      )

      worker.perform
    end
  end

  describe 'worker configuration' do
    it 'uses the cron queue without retries' do
      expect(described_class.ancestors).to include(ApplicationWorker, CronjobQueue, Gitlab::ExclusiveLeaseHelpers)
      expect(described_class.get_sidekiq_options['retry']).to be(false)
    end
  end
end
