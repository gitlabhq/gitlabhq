require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20180420080616_schedule_stages_index_migration')

describe ScheduleStagesIndexMigration, :sidekiq, :migration do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:pipelines) { table(:ci_pipelines) }
  let(:stages) { table(:ci_stages) }

  before do
    stub_const("#{described_class}::BATCH_SIZE", 1)

    namespaces.create(id: 12, name: 'gitlab-org', path: 'gitlab-org')
    projects.create!(id: 123, namespace_id: 12, name: 'gitlab', path: 'gitlab')
    pipelines.create!(id: 1, project_id: 123, ref: 'master', sha: 'adf43c3a')
    stages.create!(id: 121, project_id: 123, pipeline_id: 1, name: 'build')
    stages.create!(id: 122, project_id: 123, pipeline_id: 1, name: 'test')
    stages.create!(id: 123, project_id: 123, pipeline_id: 1, name: 'deploy')
  end

  it 'schedules delayed background migrations in batches' do
    Sidekiq::Testing.fake! do
      Timecop.freeze do
        expect(stages.all).to all(have_attributes(position: be_nil))

        migrate!

        expect(described_class::MIGRATION).to be_scheduled_delayed_migration(5.minutes, 121, 121)
        expect(described_class::MIGRATION).to be_scheduled_delayed_migration(10.minutes, 122, 122)
        expect(described_class::MIGRATION).to be_scheduled_delayed_migration(15.minutes, 123, 123)
        expect(BackgroundMigrationWorker.jobs.size).to eq 3
      end
    end
  end
end
