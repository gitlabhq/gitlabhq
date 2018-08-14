require 'spec_helper'
require Rails.root.join('db', 'migrate', '20180309121820_reschedule_commits_count_for_merge_request_diff')

describe RescheduleCommitsCountForMergeRequestDiff, :migration, :sidekiq do
  let(:merge_request_diffs) { table(:merge_request_diffs) }
  let(:merge_requests) { table(:merge_requests) }
  let(:projects) { table(:projects) }
  let(:namespaces) { table(:namespaces) }

  before do
    stub_const("#{described_class.name}::BATCH_SIZE", 1)

    namespaces.create!(id: 1, name: 'gitlab', path: 'gitlab')

    projects.create!(id: 1, namespace_id: 1)

    merge_requests.create!(id: 1, target_project_id: 1, source_project_id: 1, target_branch: 'feature', source_branch: 'master')

    merge_request_diffs.create!(id: 1, merge_request_id: 1)
    merge_request_diffs.create!(id: 2, merge_request_id: 1)
    merge_request_diffs.create!(id: 3, merge_request_id: 1, commits_count: 0)
    merge_request_diffs.create!(id: 4, merge_request_id: 1)
  end

  it 'correctly schedules background migrations' do
    Sidekiq::Testing.fake! do
      Timecop.freeze do
        migrate!

        expect(described_class::MIGRATION).to be_scheduled_delayed_migration(5.minutes, 1, 1)
        expect(described_class::MIGRATION).to be_scheduled_delayed_migration(10.minutes, 2, 2)
        expect(described_class::MIGRATION).to be_scheduled_delayed_migration(15.minutes, 4, 4)
        expect(BackgroundMigrationWorker.jobs.size).to eq 3
      end
    end
  end
end
