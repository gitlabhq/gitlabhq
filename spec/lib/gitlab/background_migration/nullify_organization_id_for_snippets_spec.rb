# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::NullifyOrganizationIdForSnippets, feature_category: :source_code_management do
  let(:organizations) { table(:organizations) }
  let(:snippets) { table(:snippets) }
  let(:projects) { table(:projects) }
  let(:namespaces) { table(:namespaces) }

  let(:organization) { organizations.create!(name: 'organization', path: 'organization') }
  let(:namespace) { namespaces.create!(name: 'foo', path: 'foo', organization_id: organization.id) }
  let!(:project) do
    projects.create!(namespace_id: namespace.id, project_namespace_id: namespace.id, organization_id: organization.id)
  end

  let!(:personal_snippet) do
    snippets.create!(
      type: 'PersonalSnippet', author_id: 1, project_id: nil, title: 'Snippet1', organization_id: 1
    )
  end

  let!(:project_snippet_with_organization) do
    snippets.create!(
      type: 'ProjectSnippet', author_id: 1, project_id: project.id, title: 'Snippet2', organization_id: 1
    )
  end

  let!(:project_snippet_without_organization) do
    snippets.create!(
      type: 'ProjectSnippet', author_id: 1, project_id: project.id, title: 'Snippet3', organization_id: nil
    )
  end

  let(:migration_attrs) do
    {
      start_id: snippets.minimum(:id),
      end_id: snippets.maximum(:id),
      batch_table: :snippets,
      batch_column: :id,
      sub_batch_size: 2,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    }
  end

  it 'nullfies organization_id for project snippets' do
    expect do
      described_class.new(**migration_attrs).perform
    end.to change { project_snippet_with_organization.reload.organization_id }.from(1).to(nil)
      .and not_change { personal_snippet.reload.organization_id }.from(1)
      .and not_change { project_snippet_without_organization.reload.organization_id }.from(nil)
  end
end
