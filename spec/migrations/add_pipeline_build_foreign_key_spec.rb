require 'spec_helper'
require Rails.root.join('db', 'migrate', '20180420010016_add_pipeline_build_foreign_key.rb')

describe AddPipelineBuildForeignKey, :migration do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:pipelines) { table(:ci_pipelines) }
  let(:builds) { table(:ci_builds) }

  before do
    namespaces.create(id: 10, name: 'gitlab-org', path: 'gitlab-org')
    projects.create!(id: 11, namespace_id: 10, name: 'gitlab', path: 'gitlab')
    pipelines.create!(id: 12, project_id: 11, ref: 'master', sha: 'adf43c3a')

    builds.create!(id: 101, commit_id: 12, project_id: 11)
    builds.create!(id: 102, commit_id: 222, project_id: 11)
    builds.create!(id: 103, commit_id: 333, project_id: 11)
    builds.create!(id: 104, commit_id: 12, project_id: 11)
    builds.create!(id: 106, commit_id: nil, project_id: 11)
    builds.create!(id: 107, commit_id: 12, project_id: nil)
  end

  it 'adds foreign key after removing orphans' do
    expect(builds.all.count).to eq 6
    expect(foreign_key_exists?(:ci_builds, :ci_pipelines, column: :commit_id)).to be_falsey

    migrate!

    expect(builds.all.pluck(:id)).to eq [101, 104]
    expect(foreign_key_exists?(:ci_builds, :ci_pipelines, column: :commit_id)).to be_truthy
  end
end
