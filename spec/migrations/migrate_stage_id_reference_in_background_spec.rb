require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20170628080858_migrate_stage_id_reference_in_background')

describe MigrateStageIdReferenceInBackground, :migration, :sidekiq do
  let(:jobs) { table(:ci_builds) }
  let(:stages) { table(:ci_stages) }
  let(:pipelines) { table(:ci_pipelines) }
  let(:projects) { table(:projects) }

  before do
    stub_const("#{described_class.name}::BATCH_SIZE", 3)
    stub_const("#{described_class.name}::RANGE_SIZE", 2)

    projects.create!(id: 123, name: 'gitlab1', path: 'gitlab1')
    projects.create!(id: 345, name: 'gitlab2', path: 'gitlab2')

    pipelines.create!(id: 1, project_id: 123, ref: 'master', sha: 'adf43c3a')
    pipelines.create!(id: 2, project_id: 345, ref: 'feature', sha: 'cdf43c3c')

    jobs.create!(id: 1, commit_id: 1, project_id: 123, stage_idx: 2, stage: 'build')
    jobs.create!(id: 2, commit_id: 1, project_id: 123, stage_idx: 2, stage: 'build')
    jobs.create!(id: 3, commit_id: 1, project_id: 123, stage_idx: 1, stage: 'test')
    jobs.create!(id: 4, commit_id: 1, project_id: 123, stage_idx: 3, stage: 'deploy')
    jobs.create!(id: 5, commit_id: 2, project_id: 345, stage_idx: 1, stage: 'test')

    stages.create(id: 101, pipeline_id: 1, project_id: 123, name: 'test')
    stages.create(id: 102, pipeline_id: 1, project_id: 123, name: 'build')
    stages.create(id: 103, pipeline_id: 1, project_id: 123, name: 'deploy')

    jobs.create!(id: 6, commit_id: 2, project_id: 345, stage_id: 101, stage_idx: 1, stage: 'test')
  end

  it 'correctly schedules background migrations' do
    Sidekiq::Testing.fake! do
      Timecop.freeze do
        migrate!

        expect(described_class::MIGRATION).to be_scheduled_delayed_migration(2.minutes, 1, 2)
        expect(described_class::MIGRATION).to be_scheduled_delayed_migration(2.minutes, 3, 3)
        expect(described_class::MIGRATION).to be_scheduled_delayed_migration(4.minutes, 4, 5)
        expect(BackgroundMigrationWorker.jobs.size).to eq 3
      end
    end
  end

  it 'schedules background migrations' do
    Sidekiq::Testing.inline! do
      expect(jobs.where(stage_id: nil).count).to eq 5

      migrate!

      expect(jobs.where(stage_id: nil).count).to eq 1
    end
  end
end
