# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::RestoreDiffCommitsWorker, feature_category: :code_review_workflow do
  include_context 'with archived merge_request_diff_commits'

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project, target_project: project) }

  let(:merge_request_diff) { merge_request.merge_request_diff }
  let(:worker) { described_class.new }
  let!(:original_shas) { merge_request_diff.commit_shas }

  def restored_shas
    merge_request_diff.reset.commit_shas(mode: :force_metadata)
  end

  describe '.schedule_for' do
    # A fresh instance per example, since #read_new_commits_table? is memoized on it.
    let(:diff) { MergeRequestDiff.find(merge_request_diff.id) }

    before do
      stub_read_new_commits_table
    end

    it 'enqueues the worker for the diff' do
      expect(described_class).to receive(:perform_async).with(diff.id)

      described_class.schedule_for(diff) { true }
    end

    it 'enqueues once per request', :request_store do
      expect(described_class).to receive(:perform_async).with(diff.id).once

      described_class.schedule_for(diff) { true }
      described_class.schedule_for(diff) { true }
    end

    it 'does not enqueue inside a transaction' do
      expect(described_class).not_to receive(:perform_async)

      MergeRequestDiff.transaction { described_class.schedule_for(diff) { true } }
    end

    context 'when the flag is disabled' do
      before do
        stub_feature_flags(restore_missing_mr_diff_commits: false)
      end

      it 'checks nothing beyond the flag', :aggregate_failures do
        expect(described_class).not_to receive(:perform_async)
        expect(diff).not_to receive(:commits_count)
        expect(diff).not_to receive(:read_new_commits_table?)

        described_class.schedule_for(diff) { raise 'predicate must not run when the flag is off' }
      end
    end

    context 'when the read found rows' do
      it 'does not enqueue' do
        expect(described_class).not_to receive(:perform_async)

        described_class.schedule_for(diff) { false }
      end
    end

    context 'when reading from the old table' do
      before do
        stub_read_new_commits_table(false)
      end

      it 'does not enqueue' do
        expect(described_class).not_to receive(:perform_async)

        described_class.schedule_for(diff) { true }
      end
    end

    context 'when the diff has no commits' do
      before do
        diff.update_column(:commits_count, 0)
      end

      it 'does not enqueue' do
        expect(described_class).not_to receive(:perform_async)

        described_class.schedule_for(diff) { true }
      end
    end

    context 'when the diff has no project_id' do
      before do
        allow(diff).to receive(:project_id).and_return(nil)
      end

      it 'does not enqueue' do
        expect(described_class).not_to receive(:perform_async)

        described_class.schedule_for(diff) { true }
      end
    end
  end

  context 'when the rows are missing' do
    before do
      archive_diff_commits(merge_request_diff)
    end

    it_behaves_like 'an idempotent worker' do
      let(:job_args) { [merge_request_diff.id] }

      it 'restores the rows from the archived table' do
        perform_idempotent_work

        expect(restored_shas).to eq(original_shas)
      end
    end

    it 'logs what it restored' do
      expect(worker).to receive(:log_extra_metadata_on_done).with(:merge_request_diff_id, merge_request_diff.id)
      expect(worker).to receive(:log_extra_metadata_on_done).with(:commits_count, original_shas.size)
      expect(worker).to receive(:log_extra_metadata_on_done).with(:inserted_rows, original_shas.size)

      worker.perform(merge_request_diff.id)
    end

    context 'when the flag is disabled' do
      before do
        stub_feature_flags(restore_missing_mr_diff_commits: false)
      end

      it 'does nothing' do
        worker.perform(merge_request_diff.id)

        expect(restored_shas).to be_empty
      end
    end

    context 'when the archived table does not exist' do
      before do
        allow(MergeRequestDiffCommit).to receive(:archived_table_exists?).and_return(false)
      end

      it 'does nothing' do
        expect(MergeRequestDiffCommit).not_to receive(:restore_from_archived)

        worker.perform(merge_request_diff.id)
      end
    end

    context 'when the diff does not exist' do
      it 'does nothing' do
        expect(MergeRequestDiffCommit).not_to receive(:restore_from_archived)

        worker.perform(non_existing_record_id)
      end
    end
  end

  context 'when the rows are present' do
    it 'does nothing' do
      expect(MergeRequestDiffCommit).not_to receive(:restore_from_archived)

      worker.perform(merge_request_diff.id)
    end
  end

  context 'when only some rows are present' do
    before do
      archive_diff_commits(merge_request_diff)
      MergeRequestDiffCommit.restore_from_archived(merge_request_diff.id)
      MergeRequestDiffCommit.where(merge_request_diff_id: merge_request_diff.id, relative_order: 0).delete_all
    end

    it 'does nothing, since it only repairs diffs with no rows at all' do
      expect(MergeRequestDiffCommit).not_to receive(:restore_from_archived)

      worker.perform(merge_request_diff.id)

      expect(restored_shas.size).to eq(original_shas.size - 1)
    end
  end

  context 'when the archived rows carry no metadata pointer' do
    before do
      archive_diff_commits(merge_request_diff)
      connection.execute(<<~SQL)
        UPDATE merge_request_diff_commits_archived SET merge_request_commits_metadata_id = NULL
        WHERE merge_request_diff_id = #{merge_request_diff.id}
      SQL
    end

    it 'inserts nothing and says so', :aggregate_failures do
      expect(worker).to receive(:log_extra_metadata_on_done).with(:merge_request_diff_id, merge_request_diff.id)
      expect(worker).to receive(:log_extra_metadata_on_done).with(:commits_count, original_shas.size)
      expect(worker).to receive(:log_extra_metadata_on_done).with(:inserted_rows, 0)

      worker.perform(merge_request_diff.id)

      expect(restored_shas).to be_empty
    end
  end
end
