require 'spec_helper'

describe Gitlab::BackgroundMigration::MigrateStageIndex, :migration, schema: 20180420080616 do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:pipelines) { table(:ci_pipelines) }
  let(:stages) { table(:ci_stages) }
  let(:jobs) { table(:ci_builds) }


  before do
    namespaces.create(id: 10, name: 'gitlab-org', path: 'gitlab-org')
    projects.create!(id: 11, namespace_id: 10, name: 'gitlab', path: 'gitlab')
    pipelines.create!(id: 12, project_id: 11, ref: 'master', sha: 'adf43c3a')

    stages.create(id: 100, project_id: 11, pipeline_id: 12, name: 'build')
    stages.create(id: 101, project_id: 11, pipeline_id: 12, name: 'test')

    jobs.create!(id: 121, commit_id: 12, project_id: 11,
                 stage_idx: 2, stage_id: 100)
    jobs.create!(id: 122, commit_id: 12, project_id: 11,
                 stage_idx: 2, stage_id: 100)
    jobs.create!(id: 123, commit_id: 12, project_id: 11,
                 stage_idx: 10, stage_id: 100)
    jobs.create!(id: 124, commit_id: 12, project_id: 11,
                 stage_idx: 3, stage_id: 101)
  end

  it 'correctly migrates stages indices' do
    expect(stages.all.pluck(:index)).to all(be_nil)

    described_class.new.perform(100, 101)

    expect(stages.all.pluck(:index)).to eq [2, 3]
  end
end
