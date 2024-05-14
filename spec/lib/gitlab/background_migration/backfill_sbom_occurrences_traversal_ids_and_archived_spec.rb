# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillSbomOccurrencesTraversalIdsAndArchived,
  feature_category: :dependency_management do
  let(:sbom_occurrences) { table(:sbom_occurrences) }
  let(:sbom_components) { table(:sbom_components) }
  let(:projects) { table(:projects) }
  let(:namespaces) { table(:namespaces) }
  let(:args) do
    min, max = sbom_occurrences.pick('MIN(id)', 'MAX(id)')

    {
      start_id: min,
      end_id: max,
      batch_table: 'sbom_occurrences',
      batch_column: 'id',
      sub_batch_size: 1,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    }
  end

  let!(:group_namespace) do
    namespaces.create!(
      name: 'gitlab-org',
      path: 'gitlab-org',
      type: 'Group'
    ).tap { |namespace| namespace.update!(traversal_ids: [namespace.id]) }
  end

  let!(:other_group_namespace) do
    namespaces.create!(
      name: 'gitlab-com',
      path: 'gitlab-com',
      type: 'Group'
    ).tap { |namespace| namespace.update!(traversal_ids: [namespace.id]) }
  end

  let!(:project) { create_project('gitlab', group_namespace) }
  let!(:other_project) { create_project('www-gitlab-com', other_group_namespace) }

  let!(:sbom_component) { sbom_components.create!(name: 'component', component_type: 0) }

  subject(:perform_migration) { described_class.new(**args).perform }

  before do
    [project, other_project].each do |p|
      sbom_occurrences.create!(
        project_id: p.id,
        commit_sha: '3bc8e151d3c4d242d76897399b8716815556673a',
        component_id: sbom_component.id,
        uuid: SecureRandom.uuid,
        traversal_ids: [],
        archived: false
      )
    end
  end

  it 'backfills traversal_ids and archived', :aggregate_failures do
    perform_migration

    sbom_occurrences.find_each do |occurrence|
      project = projects.find(occurrence.project_id)
      namespace = namespaces.find(project.namespace_id)

      expect(occurrence.traversal_ids).to eq(namespace.traversal_ids)
      expect(occurrence.archived).to eq(project.archived)
    end
  end

  def create_project(name, group)
    project_namespace = namespaces.create!(
      name: name,
      path: name,
      type: 'Project'
    )

    projects.create!(
      namespace_id: group.id,
      project_namespace_id: project_namespace.id,
      name: name,
      path: name,
      archived: true
    )
  end
end
