# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe FixPoolRepositorySourceProjectId do
  let(:projects) { table(:projects) }
  let(:pool_repositories) { table(:pool_repositories) }
  let(:shards) { table(:shards) }

  it 'fills in source_project_ids' do
    shard = shards.create!(name: 'default')

    # gitaly is a project with a pool repository that has a source_project_id
    gitaly = projects.create!(name: 'gitaly', path: 'gitlab-org/gitaly', namespace_id: 1)
    pool_repository = pool_repositories.create!(shard_id: shard.id, source_project_id: gitaly.id)
    gitaly.update_column(:pool_repository_id, pool_repository.id)

    # gitlab is a project with a pool repository that's missing a source_project_id
    pool_repository_without_source_project = pool_repositories.create!(shard_id: shard.id, source_project_id: nil)
    gitlab = projects.create!(name: 'gitlab', path: 'gitlab-org/gitlab-ce', namespace_id: 1, pool_repository_id: pool_repository_without_source_project.id)
    projects.create!(name: 'gitlab-fork-1', path: 'my-org-1/gitlab-ce', namespace_id: 1, pool_repository_id: pool_repository_without_source_project.id)

    migrate!

    expect(pool_repositories.find(pool_repository_without_source_project.id).source_project_id).to eq(gitlab.id)
    expect(pool_repositories.find(pool_repository.id).source_project_id).to eq(gitaly.id)
  end
end
