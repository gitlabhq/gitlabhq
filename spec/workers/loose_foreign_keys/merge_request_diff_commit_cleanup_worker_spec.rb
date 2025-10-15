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

  describe 'E2E cleanup functionality' do
    let_it_be(:project) { create(:project) }
    let_it_be(:merge_request) { create(:merge_request, source_project: project) }
    let_it_be(:diff) { create(:merge_request_diff, merge_request: merge_request) }

    it 'processes LFK records and deletes merge_request_diff_commits' do
      # Create a diff commit record that should be cleaned up when the diff is deleted
      diff_commit = create(:merge_request_diff_commit, merge_request_diff: diff)
      diff_id = diff.id

      # Verify the association exists
      expect(diff_commit.merge_request_diff_id).to eq(diff_id)

      # Verify the diff commit exists before cleanup
      expect(MergeRequestDiffCommit.find(diff_commit.id)).to eq(diff_commit)

      # Actually delete the merge_request_diff - this should trigger the LFK mechanism
      # The LFK trigger should automatically create the deleted record
      diff.delete

      # Verify the LFK record was created by the trigger and that running the worker processes it
      expect do
        worker.perform
      end.to change {
        LooseForeignKeys::DeletedRecord.where(
          fully_qualified_table_name: 'public.merge_request_diffs',
          primary_key_value: diff_id
        ).first.try(:status)
      }.from('pending').to('processed')

      # Verify that the diff commit is now gone
      expect { MergeRequestDiffCommit.find(diff_commit.id) }
        .to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
