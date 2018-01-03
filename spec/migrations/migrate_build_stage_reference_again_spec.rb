require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20170526190000_migrate_build_stage_reference_again.rb')

describe MigrateBuildStageReferenceAgain, :migration do
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
    jobs.create!(id: 4, commit_id: 1, project_id: 123, stage_idx: 3, stage: 'deploy')
    jobs.create!(id: 5, commit_id: 2, project_id: 456, stage_idx: 2, stage: 'test:2')
    jobs.create!(id: 6, commit_id: 2, project_id: 456, stage_idx: 1, stage: 'test:1')
    jobs.create!(id: 7, commit_id: 2, project_id: 456, stage_idx: 1, stage: 'test:1')
    jobs.create!(id: 8, commit_id: 3, project_id: 789, stage_idx: 3, stage: 'deploy')

    # Create CI/CD stages
    #
    stages.create(id: 101, pipeline_id: 1, project_id: 123, name: 'test')
    stages.create(id: 102, pipeline_id: 1, project_id: 123, name: 'build')
    stages.create(id: 103, pipeline_id: 1, project_id: 123, name: 'deploy')
    stages.create(id: 104, pipeline_id: 2, project_id: 456, name: 'test:1')
    stages.create(id: 105, pipeline_id: 2, project_id: 456, name: 'test:2')
    stages.create(id: 106, pipeline_id: 2, project_id: 456, name: 'deploy')
  end

  it 'correctly migrate build stage references' do
    expect(jobs.where(stage_id: nil).count).to eq 8

    migrate!

    expect(jobs.where(stage_id: nil).count).to eq 1

    expect(jobs.find(1).stage_id).to eq 102
    expect(jobs.find(2).stage_id).to eq 102
    expect(jobs.find(3).stage_id).to eq 101
    expect(jobs.find(4).stage_id).to eq 103
    expect(jobs.find(5).stage_id).to eq 105
    expect(jobs.find(6).stage_id).to eq 104
    expect(jobs.find(7).stage_id).to eq 104
    expect(jobs.find(8).stage_id).to eq nil
  end
end
