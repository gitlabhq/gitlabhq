require 'spec_helper'

describe Gitlab::BackgroundMigration::ScheduleDiffFilesDeletion, :migration, :sidekiq, schema: 20180619121030 do
  describe '#perform' do
    let(:merge_request_diffs) { table(:merge_request_diffs) }
    let(:merge_requests) { table(:merge_requests) }
    let(:namespaces) { table(:namespaces) }
    let(:projects) { table(:projects) }

    before do
      stub_const("#{described_class.name}::DIFF_BATCH_SIZE", 3)

      namespaces.create!(id: 1, name: 'gitlab', path: 'gitlab')
      projects.create!(id: 1, namespace_id: 1, name: 'gitlab', path: 'gitlab')

      merge_requests.create!(id: 1, target_project_id: 1, source_project_id: 1, target_branch: 'feature', source_branch: 'master', state: 'merged')

      merge_request_diffs.create!(id: 1, merge_request_id: 1, state: 'collected')
      merge_request_diffs.create!(id: 2, merge_request_id: 1, state: 'empty')
      merge_request_diffs.create!(id: 3, merge_request_id: 1, state: 'without_files')
      merge_request_diffs.create!(id: 4, merge_request_id: 1, state: 'collected')
      merge_request_diffs.create!(id: 5, merge_request_id: 1, state: 'collected')
      merge_request_diffs.create!(id: 6, merge_request_id: 1, state: 'collected')
      merge_request_diffs.create!(id: 7, merge_request_id: 1, state: 'collected')

      merge_requests.update(1, latest_merge_request_diff_id: 7)
    end

    it 'correctly schedules diff file deletion workers' do
      Sidekiq::Testing.fake! do
        Timecop.freeze do
          described_class.new.perform

          expect(described_class::MIGRATION).to be_scheduled_delayed_migration(5.minutes, [1, 4, 5])

          expect(described_class::MIGRATION).to be_scheduled_delayed_migration(10.minutes, [6])

          expect(BackgroundMigrationWorker.jobs.size).to eq(2)
        end
      end
    end
  end
end
