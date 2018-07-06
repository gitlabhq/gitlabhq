require 'spec_helper'

describe Gitlab::BackgroundMigration::DeleteDiffFiles, :migration, schema: 20180619121030 do
  describe '#perform' do
    context 'when diff files can be deleted' do
      let(:merge_request) { create(:merge_request, :merged) }
      let!(:merge_request_diff) do
        merge_request.create_merge_request_diff
        merge_request.merge_request_diffs.first
      end

      it 'deletes all merge request diff files' do
        expect { described_class.new.perform }
          .to change { merge_request_diff.merge_request_diff_files.count }
          .from(20).to(0)
      end

      it 'updates state to without_files' do
        expect { described_class.new.perform }
          .to change { merge_request_diff.reload.state }
          .from('collected').to('without_files')
      end

      it 'rollsback if something goes wrong' do
        expect(described_class::MergeRequestDiffFile).to receive_message_chain(:where, :delete_all)
          .and_raise

        expect { described_class.new.perform }
          .to raise_error

        merge_request_diff.reload

        expect(merge_request_diff.state).to eq('collected')
        expect(merge_request_diff.merge_request_diff_files.count).to eq(20)
      end
    end

    it 'deletes no merge request diff files when MR is not merged' do
      merge_request = create(:merge_request, :opened)
      merge_request.create_merge_request_diff
      merge_request_diff = merge_request.merge_request_diffs.first

      expect { described_class.new.perform }
        .not_to change { merge_request_diff.merge_request_diff_files.count }
        .from(20)
    end

    it 'deletes no merge request diff files when diff is marked as "without_files"' do
      merge_request = create(:merge_request, :merged)
      merge_request.create_merge_request_diff
      merge_request_diff = merge_request.merge_request_diffs.first

      merge_request_diff.clean!

      expect { described_class.new.perform }
        .not_to change { merge_request_diff.merge_request_diff_files.count }
        .from(20)
    end

    it 'deletes no merge request diff files when diff is the latest' do
      merge_request = create(:merge_request, :merged)
      merge_request_diff = merge_request.merge_request_diff

      expect { described_class.new.perform }
        .not_to change { merge_request_diff.merge_request_diff_files.count }
        .from(20)
    end

    it 'reschedules itself when should_wait_deadtuple_vacuum' do
      Sidekiq::Testing.fake! do
        worker = described_class.new

        allow(worker).to receive(:should_wait_deadtuple_vacuum?) { true }

        expect(BackgroundMigrationWorker)
          .to receive(:perform_in)
          .with(described_class::VACUUM_WAIT_TIME, 'DeleteDiffFiles')
          .and_call_original

        worker.perform

        expect(BackgroundMigrationWorker.jobs.size).to eq(1)
      end
    end
  end

  describe '#should_wait_deadtuple_vacuum?' do
    it 'returns true when hitting merge_request_diff_files hits DEAD_TUPLES_THRESHOLD', :postgresql do
      worker = described_class.new
      threshold_query_result = [{ "n_dead_tup" => described_class::DEAD_TUPLES_THRESHOLD.to_s }]
      normal_query_result = [{ "n_dead_tup" => '3' }]

      allow(worker)
        .to receive(:execute_statement)
        .with(/SELECT n_dead_tup */)
        .and_return(threshold_query_result, normal_query_result)

      expect(worker.should_wait_deadtuple_vacuum?).to be(true)
    end
  end
end
