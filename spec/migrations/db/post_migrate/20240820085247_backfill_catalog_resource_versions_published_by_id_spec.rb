# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillCatalogResourceVersionsPublishedById,
  migration: :gitlab_main,
  feature_category: :pipeline_composition do
  let(:catalog_resource_versions) { table(:catalog_resource_versions) }
  let(:releases) { table(:releases) }
  let(:users) { table(:users) }

  let!(:namespace) { table(:namespaces).create!(name: 'namespace', path: 'namespace') }
  let!(:project) { table(:projects).create!(namespace_id: namespace.id, project_namespace_id: namespace.id) }
  let!(:resource) { table(:catalog_resources).create!(project_id: project.id) }

  let!(:user1) { users.create!(email: 'test1@example.com', projects_limit: 10) }
  let!(:user2) { users.create!(email: 'test2@example.com', projects_limit: 10) }

  let!(:release1) do
    releases.create!(author_id: user1.id, project_id: project.id, released_at: Time.current, tag: 'v1')
  end

  let!(:release2) do
    releases.create!(author_id: user2.id, project_id: project.id, released_at: Time.current, tag: 'v2')
  end

  let!(:catalog_resource_version1) do
    catalog_resource_versions.create!(
      release_id: release1.id,
      published_by_id: nil,
      catalog_resource_id: resource.id,
      project_id: project.id
    )
  end

  let!(:catalog_resource_version2) do
    catalog_resource_versions.create!(
      release_id: release2.id,
      published_by_id: release2.author_id,
      catalog_resource_id: resource.id,
      project_id: project.id
    )
  end

  it 'correctly backfills published_by_id' do
    migrate!

    expect(catalog_resource_version1.reload.published_by_id).to eq(user1.id)
    expect(catalog_resource_version2.reload.published_by_id).to eq(user2.id)
  end
end
