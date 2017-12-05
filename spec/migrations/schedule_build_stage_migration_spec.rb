require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20171205101928_schedule_build_stage_migration')

describe ScheduleBuildStageMigration, :migration do
  let(:projects) { table(:projects) }
  let(:pipelines) { table(:ci_pipelines) }
  let(:stages) { table(:ci_stages) }
  let(:jobs) { table(:ci_builds) }

  before do
    ##
    # Dependencies
    #
    projects.create!(id: 123, name: 'gitlab', path: 'gitlab-ce')
    pipelines.create!(id: 1, project_id: 123, ref: 'master', sha: 'adf43c3a')
    stages.create!(id: 1, project_id: 123, pipeline_id: 1, name: 'test')

    ##
    # CI/CD jobs
    #
    jobs.create!(id: 10, commit_id: 1, project_id: 123, stage_id: nil)
    jobs.create!(id: 20, commit_id: 1, project_id: 123, stage_id: nil)
    jobs.create!(id: 30, commit_id: 1, project_id: 123, stage_id: nil)
    jobs.create!(id: 40, commit_id: 1, project_id: 123, stage_id: 1)
  end

  before do
    stub_const("#{described_class}::BATCH", 1)
  end

  it 'schedules background migrations in batches in bulk' do
    Sidekiq::Testing.fake! do
      Timecop.freeze do
        migrate!

        expect(described_class::MIGRATION).to be_scheduled_migration(1.minutes, 10)
        expect(described_class::MIGRATION).to be_scheduled_migration(2.minutes, 20)
        expect(described_class::MIGRATION).to be_scheduled_migration(3.minutes, 30)
        expect(BackgroundMigrationWorker.jobs.size).to eq 3
      end
    end
  end
end
