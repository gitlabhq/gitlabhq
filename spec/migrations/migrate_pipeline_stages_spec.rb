require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20170526185842_migrate_pipeline_stages.rb')

describe MigratePipelineStages, :migration do
  ##
  # Create test data - pipeline and CI/CD jobs.
  #

  let(:jobs) { table(:ci_builds) }
  let(:stages) { table(:ci_stages) }
  let(:pipelines) { table(:ci_pipelines) }
  let(:projects) { table(:projects) }

  before do
    # Create projects
    #
    projects.create!(id: 123, name: 'gitlab1', path: 'gitlab1')
    projects.create!(id: 456, name: 'gitlab2', path: 'gitlab2')

    # Create CI/CD pipelines
    #
    pipelines.create!(id: 1, project_id: 123, ref: 'master', sha: 'adf43c3a')
    pipelines.create!(id: 2, project_id: 456, ref: 'feature', sha: '21a3deb')

    # Create CI/CD jobs
    #
    jobs.create!(id: 1, commit_id: 1, project_id: 123, stage_idx: 2, stage: 'build')
    jobs.create!(id: 2, commit_id: 1, project_id: 123, stage_idx: 2, stage: 'build')
    jobs.create!(id: 3, commit_id: 1, project_id: 123, stage_idx: 1, stage: 'test')
    jobs.create!(id: 4, commit_id: 1, project_id: 123, stage_idx: 1, stage: 'test')
    jobs.create!(id: 5, commit_id: 1, project_id: 123, stage_idx: 3, stage: 'deploy')
    jobs.create!(id: 6, commit_id: 2, project_id: 456, stage_idx: 3, stage: 'deploy')
    jobs.create!(id: 7, commit_id: 2, project_id: 456, stage_idx: 2, stage: 'test:2')
    jobs.create!(id: 8, commit_id: 2, project_id: 456, stage_idx: 1, stage: 'test:1')
    jobs.create!(id: 9, commit_id: 2, project_id: 456, stage_idx: 1, stage: 'test:1')
    jobs.create!(id: 10, commit_id: 2, project_id: 456, stage_idx: 2, stage: 'test:2')
    jobs.create!(id: 11, commit_id: 3, project_id: 456, stage_idx: 3, stage: 'deploy')
    jobs.create!(id: 12, commit_id: 2, project_id: 789, stage_idx: 3, stage: 'deploy')
  end

  it 'correctly migrates pipeline stages' do
    expect(stages.count).to be_zero

    migrate!

    expect(stages.count).to eq 6
    expect(stages.all.pluck(:name))
      .to match_array %w[test build deploy test:1 test:2 deploy]
    expect(stages.where(pipeline_id: 1).order(:id).pluck(:name))
      .to eq %w[test build deploy]
    expect(stages.where(pipeline_id: 2).order(:id).pluck(:name))
      .to eq %w[test:1 test:2 deploy]
    expect(stages.where(pipeline_id: 3).count).to be_zero
    expect(stages.where(project_id: 789).count).to be_zero
  end
end
