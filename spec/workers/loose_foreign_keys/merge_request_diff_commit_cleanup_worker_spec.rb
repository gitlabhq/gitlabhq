# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LooseForeignKeys::MergeRequestDiffCommitCleanupWorker, feature_category: :source_code_management do
  let(:worker) { described_class.new }

  describe '#perform' do
    it 'passes the correct worker_class to ProcessDeletedRecordsService' do
      expect(LooseForeignKeys::ProcessDeletedRecordsService).to receive(:new).with(
        hash_including(worker_class: described_class)
      ).and_call_original

      allow_next_instance_of(LooseForeignKeys::ProcessDeletedRecordsService) do |service|
        allow(service).to receive(:execute).and_return({ delete_count: 0, update_count: 0 })
      end

      worker.perform
    end

    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(use_merge_request_diff_commit_cleanup_worker: false)
      end

      it 'does not execute cleanup' do
        expect(LooseForeignKeys::ProcessDeletedRecordsService).not_to receive(:new)

        worker.perform
      end
    end

    context 'when vacuum is running on merge_request_diff_commits table' do
      before do
        allow(Gitlab::Database::PostgresAutovacuumActivity).to receive(:for_tables)
          .with(['merge_request_diff_commits'])
          .and_return([instance_double(Gitlab::Database::PostgresAutovacuumActivity)])
      end

      it 'does not execute cleanup and logs vacuum running' do
        expect(LooseForeignKeys::ProcessDeletedRecordsService).not_to receive(:new)
        expect(worker).to receive(:log_extra_metadata_on_done).with(:vacuum_running, true)

        worker.perform
      end
    end
  end

  describe '#vacuum_running_on_merge_request_diff_commits?' do
    context 'when vacuum is running' do
      before do
        allow(Gitlab::Database::PostgresAutovacuumActivity).to receive(:for_tables)
          .with(['merge_request_diff_commits'])
          .and_return([instance_double(Gitlab::Database::PostgresAutovacuumActivity)])
      end

      it 'returns true' do
        expect(worker.send(:vacuum_running_on_merge_request_diff_commits?)).to be true
      end
    end

    context 'when vacuum is not running' do
      before do
        allow(Gitlab::Database::PostgresAutovacuumActivity).to receive(:for_tables)
          .with(['merge_request_diff_commits'])
          .and_return([])
      end

      it 'returns false' do
        expect(worker.send(:vacuum_running_on_merge_request_diff_commits?)).to be false
      end
    end
  end

  describe 'worker configuration' do
    it 'has correct Sidekiq configuration' do
      expect(described_class.ancestors).to include(ApplicationWorker)
      expect(described_class.ancestors).to include(Gitlab::ExclusiveLeaseHelpers)
      expect(described_class.get_sidekiq_options['retry']).to be_falsey
    end
  end
end
