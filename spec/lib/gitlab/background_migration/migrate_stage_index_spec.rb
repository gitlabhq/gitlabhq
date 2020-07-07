# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::MigrateStageIndex do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:pipelines) { table(:ci_pipelines) }
  let(:stages) { table(:ci_stages) }
  let(:jobs) { table(:ci_builds) }
  let(:namespace) { namespaces.create(name: 'gitlab-org', path: 'gitlab-org') }
  let(:project) { projects.create!(namespace_id: namespace.id, name: 'gitlab', path: 'gitlab') }
  let(:pipeline) { pipelines.create!(project_id: project.id, ref: 'master', sha: 'adf43c3a') }
  let(:stage1) { stages.create(project_id: project.id, pipeline_id: pipeline.id, name: 'build') }
  let(:stage2) { stages.create(project_id: project.id, pipeline_id: pipeline.id, name: 'test') }

  before do
    jobs.create!(commit_id: pipeline.id, project_id: project.id,
                 stage_idx: 2, stage_id: stage1.id)
    jobs.create!(commit_id: pipeline.id, project_id: project.id,
                 stage_idx: 2, stage_id: stage1.id)
    jobs.create!(commit_id: pipeline.id, project_id: project.id,
                 stage_idx: 10, stage_id: stage1.id)
    jobs.create!(commit_id: pipeline.id, project_id: project.id,
                 stage_idx: 3, stage_id: stage2.id)
  end

  it 'correctly migrates stages indices' do
    expect(stages.all.pluck(:position)).to all(be_nil)

    described_class.new.perform(stage1.id, stage2.id)

    expect(stages.all.order(:id).pluck(:position)).to eq [2, 3]
  end
end
