require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20170926150348_schedule_merge_request_diff_migrations_take_two')

describe ScheduleMergeRequestDiffMigrationsTakeTwo, :migration, :sidekiq do
  let(:merge_request_diffs) { table(:merge_request_diffs) }
  let(:merge_requests) { table(:merge_requests) }
  let(:projects) { table(:projects) }

  before do
    stub_const("#{described_class.name}::BATCH_SIZE", 1)

    projects.create!(id: 1, name: 'gitlab', path: 'gitlab')

    merge_requests.create!(id: 1, target_project_id: 1, source_project_id: 1, target_branch: 'feature', source_branch: 'master')

    merge_request_diffs.create!(id: 1, merge_request_id: 1, st_commits: YAML.dump([]), st_diffs: nil)
    merge_request_diffs.create!(id: 2, merge_request_id: 1, st_commits: nil, st_diffs: YAML.dump([]))
    merge_request_diffs.create!(id: 3, merge_request_id: 1, st_commits: nil, st_diffs: nil)
    merge_request_diffs.create!(id: 4, merge_request_id: 1, st_commits: YAML.dump([]), st_diffs: YAML.dump([]))
  end

  it 'correctly schedules background migrations' do
    Sidekiq::Testing.fake! do
      Timecop.freeze do
        migrate!

        expect(described_class::MIGRATION).to be_scheduled_delayed_migration(10.minutes, 1, 1)
        expect(described_class::MIGRATION).to be_scheduled_delayed_migration(20.minutes, 2, 2)
        expect(described_class::MIGRATION).to be_scheduled_delayed_migration(30.minutes, 4, 4)
        expect(BackgroundMigrationWorker.jobs.size).to eq 3
      end
    end
  end

  it 'migrates the data' do
    Sidekiq::Testing.inline! do
      non_empty = 'st_commits IS NOT NULL OR st_diffs IS NOT NULL'

      expect(merge_request_diffs.where(non_empty).count).to eq 3

      migrate!

      expect(merge_request_diffs.where(non_empty).count).to eq 0
    end
  end
end
