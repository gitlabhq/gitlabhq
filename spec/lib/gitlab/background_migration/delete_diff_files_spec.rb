require 'spec_helper'

# rubocop:disable RSpec/FactoriesInMigrationSpecs
describe Gitlab::BackgroundMigration::DeleteDiffFiles, :migration, :sidekiq, schema: 20180619121030 do
  describe '#perform' do
    before do
      # This migration was created before we introduced ProjectCiCdSetting#default_git_depth
      allow_any_instance_of(ProjectCiCdSetting).to receive(:default_git_depth=).and_return(0)
      allow_any_instance_of(ProjectCiCdSetting).to receive(:default_git_depth).and_return(nil)
    end

    context 'when diff files can be deleted' do
      let(:merge_request) { create(:merge_request, :merged) }
      let!(:merge_request_diff) do
        merge_request.create_merge_request_diff
        merge_request.merge_request_diffs.first
      end

      let(:perform) do
        described_class.new.perform(MergeRequestDiff.pluck(:id))
      end

      it 'deletes all merge request diff files' do
        expect { perform }
          .to change { merge_request_diff.merge_request_diff_files.count }
          .from(20).to(0)
      end

      it 'updates state to without_files' do
        expect { perform }
          .to change { merge_request_diff.reload.state }
          .from('collected').to('without_files')
      end

      it 'rollsback if something goes wrong' do
        expect(described_class::MergeRequestDiffFile).to receive_message_chain(:where, :delete_all)
          .and_raise

        expect { perform }
          .to raise_error

        merge_request_diff.reload

        expect(merge_request_diff.state).to eq('collected')
        expect(merge_request_diff.merge_request_diff_files.count).to eq(20)
      end
    end

    it 'reschedules itself when should_wait_deadtuple_vacuum' do
      merge_request = create(:merge_request, :merged)
      first_diff = merge_request.merge_request_diff
      second_diff = merge_request.create_merge_request_diff

      Sidekiq::Testing.fake! do
        worker = described_class.new
        allow(worker).to receive(:should_wait_deadtuple_vacuum?) { true }

        worker.perform([first_diff.id, second_diff.id])

        expect(described_class.name.demodulize).to be_scheduled_delayed_migration(5.minutes, [first_diff.id, second_diff.id])
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
# rubocop:enable RSpec/FactoriesInMigrationSpecs
