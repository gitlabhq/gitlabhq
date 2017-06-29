require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20170628080858_migrate_stage_id_reference_in_background')

describe MigrateStageIdReferenceInBackground, :migration, :sidekiq do
  matcher :have_scheduled_migration do |delay, *expected|
    match do |migration|
      BackgroundMigrationWorker.jobs.any? do |job|
        job['args'] == [migration, expected] &&
          job['at'].to_f == (delay.to_f + Time.now.to_f)
      end
    end

    failure_message do |migration|
      "Migration `#{migration}` with args `#{expected.inspect}` not scheduled!"
    end
  end

  let(:jobs) { table(:ci_builds) }
  let(:stages) { table(:ci_stages) }
  let(:pipelines) { table(:ci_pipelines) }
  let(:projects) { table(:projects) }

  before do
    stub_const('MigrateStageIdReferenceInBackground::BATCH_SIZE', 2)

    projects.create!(id: 123, name: 'gitlab1', path: 'gitlab1')
    pipelines.create!(id: 1, project_id: 123, ref: 'master', sha: 'adf43c3a')

    jobs.create!(id: 1, commit_id: 1, project_id: 123, stage_idx: 2, stage: 'build')
    jobs.create!(id: 2, commit_id: 1, project_id: 123, stage_idx: 2, stage: 'build')
    jobs.create!(id: 3, commit_id: 1, project_id: 123, stage_idx: 1, stage: 'test')
    jobs.create!(id: 4, commit_id: 1, project_id: 123, stage_idx: 3, stage: 'deploy')

    stages.create(id: 101, pipeline_id: 1, project_id: 123, name: 'test')
    stages.create(id: 102, pipeline_id: 1, project_id: 123, name: 'build')
    stages.create(id: 103, pipeline_id: 1, project_id: 123, name: 'deploy')
  end

  it 'correctly schedules background migrations' do
    Sidekiq::Testing.fake! do
      Timecop.freeze do
        migrate!

        expect(described_class::MIGRATION).to have_scheduled_migration(5.minutes, 1)
        expect(described_class::MIGRATION).to have_scheduled_migration(5.minutes, 2)
        expect(described_class::MIGRATION).to have_scheduled_migration(10.minutes, 3)
        expect(described_class::MIGRATION).to have_scheduled_migration(10.minutes, 4)
      end
    end
  end

  it 'schedules background migrations' do
    Sidekiq::Testing.inline! do
      expect(jobs.where(stage_id: nil)).to be_present

      migrate!

      expect(jobs.where(stage_id: nil)).to be_empty
    end
  end
end
