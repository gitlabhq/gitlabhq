require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20171026082505_schedule_merge_request_latest_merge_request_diff_id_migrations')

describe ScheduleMergeRequestLatestMergeRequestDiffIdMigrations, :migration, :sidekiq do
  let(:projects_table) { table(:projects) }
  let(:merge_requests_table) { table(:merge_requests) }
  let(:merge_request_diffs_table) { table(:merge_request_diffs) }

  let(:project) { projects_table.create!(name: 'gitlab', path: 'gitlab-org/gitlab-ce') }

  let!(:merge_request_1) { create_mr!('mr_1', diffs: 1) }
  let!(:merge_request_2) { create_mr!('mr_2', diffs: 2) }
  let!(:merge_request_migrated) { create_mr!('merge_request_migrated', diffs: 3) }
  let!(:merge_request_4) { create_mr!('mr_4', diffs: 3) }

  def create_mr!(name, diffs: 0)
    merge_request =
      merge_requests_table.create!(target_project_id: project.id,
                                   target_branch: 'master',
                                   source_project_id: project.id,
                                   source_branch: name,
                                   title: name)

    diffs.times do
      merge_request_diffs_table.create!(merge_request_id: merge_request.id)
    end

    merge_request
  end

  def diffs_for(merge_request)
    merge_request_diffs_table.where(merge_request_id: merge_request.id)
  end

  before do
    stub_const("#{described_class.name}::BATCH_SIZE", 1)

    diff_id = diffs_for(merge_request_migrated).minimum(:id)
    merge_request_migrated.update!(latest_merge_request_diff_id: diff_id)
  end

  it 'correctly schedules background migrations' do
    Sidekiq::Testing.fake! do
      Timecop.freeze do
        migrate!

        expect(described_class::MIGRATION).to be_scheduled_delayed_migration(5.minutes, merge_request_1.id, merge_request_1.id)
        expect(described_class::MIGRATION).to be_scheduled_delayed_migration(10.minutes, merge_request_2.id, merge_request_2.id)
        expect(described_class::MIGRATION).to be_scheduled_delayed_migration(15.minutes, merge_request_4.id, merge_request_4.id)
        expect(BackgroundMigrationWorker.jobs.size).to eq 3
      end
    end
  end

  it 'schedules background migrations' do
    Sidekiq::Testing.inline! do
      expect(merge_requests_table.where(latest_merge_request_diff_id: nil).count).to eq 3

      migrate!

      expect(merge_requests_table.where(latest_merge_request_diff_id: nil).count).to eq 0
    end
  end
end
