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

    pipelines.create!(id: 1, project_id: 123, ref: 'master', sha: 'adf43c3a')
    pipelines.create!(id: 2, project_id: 456, ref: 'feature', sha: '21a3deb')

    create_job(project: 1, pipeline: 1, stage: 'test', status: 'success')
    create_job(project: 1, pipeline: 1, stage: 'test', status: 'running')
    create_job(project: 1, pipeline: 1, stage: 'build', status: 'success')
    create_job(project: 1, pipeline: 1, stage: 'build', status: 'failed')
    create_job(project: 2, pipeline: 2, stage: 'test', status: 'success')
    create_job(project: 2, pipeline: 2, stage: 'test', status: 'succcss')

    stages.create!(id: 1, pipeline_id: 1, project_id: 1, status: nil)
    stages.create!(id: 2, pipeline_id: 1, project_id: 1, status: nil)
    stages.create!(id: 3, pipeline_id: 2, project_id: 2, status: nil)
  end

  pending 'correctly migrates stages statuses' do
    expect(stages.where(status: nil).count).to eq 3

    migrate!

    expect(stages.where(status: nil)).to be_empty
    expect(stages.all.order(:id, :asc).pluck(:stage))
      .to eq %w[running success failed]
  end

  def create_job(project:, pipeline:, stage:, status:)
    stage_idx = STAGES[stage.to_sym]
    status_id = STATUSES[status.to_sym]

    jobs.create!(project_id: project, commit_id: pipeline,
                 stage_idx: stage_idx, stage: stage, status: status_id)
  end
end
