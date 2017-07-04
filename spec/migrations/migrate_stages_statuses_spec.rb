require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20170630111158_migrate_stages_statuses.rb')

describe MigrateStagesStatuses, :migration do
  let(:jobs) { table(:ci_builds) }
  let(:stages) { table(:ci_stages) }
  let(:pipelines) { table(:ci_pipelines) }
  let(:projects) { table(:projects) }

  STATUSES = { created: 0, pending: 1, running: 2, success: 3,
               failed: 4, canceled: 5, skipped: 6, manual: 7 }
  STAGES  = { test: 1, build: 2, deploy: 3}

  before do
    projects.create!(id: 1, name: 'gitlab1', path: 'gitlab1')
    projects.create!(id: 2, name: 'gitlab2', path: 'gitlab2')

    pipelines.create!(id: 1, project_id: 1, ref: 'master', sha: 'adf43c3a')
    pipelines.create!(id: 2, project_id: 2, ref: 'feature', sha: '21a3deb')

    create_job(project: 1, pipeline: 1, stage: 'test', status: 'success')
    create_job(project: 1, pipeline: 1, stage: 'test', status: 'running')
    create_job(project: 1, pipeline: 1, stage: 'build', status: 'success')
    create_job(project: 1, pipeline: 1, stage: 'build', status: 'failed')
    create_job(project: 2, pipeline: 2, stage: 'test', status: 'success')
    create_job(project: 2, pipeline: 2, stage: 'test', status: 'success')

    stages.create!(id: 1, pipeline_id: 1, project_id: 1, name: 'test', status: nil)
    stages.create!(id: 2, pipeline_id: 1, project_id: 1, name: 'build', status: nil)
    stages.create!(id: 3, pipeline_id: 2, project_id: 2, name: 'test', status: nil)
  end

  it 'correctly migrates stages statuses' do
    expect(stages.where(status: nil).count).to eq 3

    migrate!

    expect(stages.where(status: nil)).to be_empty
    expect(stages.all.order('id ASC').pluck(:status))
      .to eq [STATUSES[:running], STATUSES[:failed], STATUSES[:success]]
  end

  def create_job(project:, pipeline:, stage:, status:)
    stage_idx = STAGES[stage.to_sym]

    jobs.create!(project_id: project, commit_id: pipeline,
                 stage_idx: stage_idx, stage: stage, status: status)
  end
end
