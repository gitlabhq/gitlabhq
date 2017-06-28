require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20170628080858_migrate_stage_id_reference_in_background')

describe MigrateStageIdReferenceInBackground, :migration, :redis do
  let(:jobs) { table(:ci_builds) }
  let(:stages) { table(:ci_stages) }
  let(:pipelines) { table(:ci_pipelines) }
  let(:projects) { table(:projects) }

  before do
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

  it 'schedules background migrations' do
    expect(jobs.where(stage_id: nil)).to be_present

    migrate!

    expect(jobs.where(stage_id: nil)).to be_empty
  end
end
