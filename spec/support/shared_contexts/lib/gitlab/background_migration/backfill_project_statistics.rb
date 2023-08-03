# frozen_string_literal: true

RSpec.shared_context 'when backfilling project statistics' do
  let!(:namespaces) { table(:namespaces) }
  let!(:project_statistics_table) { table(:project_statistics) }
  let!(:projects) { table(:projects) }
  let!(:count_of_columns) { ProjectStatistics::STORAGE_SIZE_COMPONENTS.count }
  let(:default_storage_size) { 12 }

  let!(:root_group) do
    namespaces.create!(name: 'root-group', path: 'root-group', type: 'Group') do |new_group|
      new_group.update!(traversal_ids: [new_group.id])
    end
  end

  let!(:group) do
    namespaces.create!(name: 'group', path: 'group', parent_id: root_group.id, type: 'Group') do |new_group|
      new_group.update!(traversal_ids: [root_group.id, new_group.id])
    end
  end

  let!(:sub_group) do
    namespaces.create!(name: 'subgroup', path: 'subgroup', parent_id: group.id, type: 'Group') do |new_group|
      new_group.update!(traversal_ids: [root_group.id, group.id, new_group.id])
    end
  end

  let!(:namespace1) do
    namespaces.create!(
      name: 'namespace1', type: 'Group', path: 'space1'
    )
  end

  let!(:proj_namespace1) do
    namespaces.create!(
      name: 'proj1', path: 'proj1', type: 'Project', parent_id: namespace1.id
    )
  end

  let!(:proj_namespace2) do
    namespaces.create!(
      name: 'proj2', path: 'proj2', type: 'Project', parent_id: namespace1.id
    )
  end

  let!(:proj_namespace3) do
    namespaces.create!(
      name: 'proj3', path: 'proj3', type: 'Project', parent_id: sub_group.id
    )
  end

  let!(:proj_namespace4) do
    namespaces.create!(
      name: 'proj4', path: 'proj4', type: 'Project', parent_id: sub_group.id
    )
  end

  let!(:proj_namespace5) do
    namespaces.create!(
      name: 'proj5', path: 'proj5', type: 'Project', parent_id: sub_group.id
    )
  end

  let!(:proj1) do
    projects.create!(
      name: 'proj1', path: 'proj1', namespace_id: namespace1.id, project_namespace_id: proj_namespace1.id
    )
  end

  let!(:proj2) do
    projects.create!(
      name: 'proj2', path: 'proj2', namespace_id: namespace1.id, project_namespace_id: proj_namespace2.id
    )
  end

  let!(:proj3) do
    projects.create!(
      name: 'proj3', path: 'proj3', namespace_id: sub_group.id, project_namespace_id: proj_namespace3.id
    )
  end

  let!(:proj4) do
    projects.create!(
      name: 'proj4', path: 'proj4', namespace_id: sub_group.id, project_namespace_id: proj_namespace4.id
    )
  end

  let!(:proj5) do
    projects.create!(
      name: 'proj5', path: 'proj5', namespace_id: sub_group.id, project_namespace_id: proj_namespace5.id
    )
  end

  let(:migration) do
    described_class.new(start_id: 1, end_id: proj4.id,
      batch_table: 'project_statistics', batch_column: 'project_id',
      sub_batch_size: 1_000, pause_ms: 0,
      connection: ApplicationRecord.connection)
  end

  let(:default_projects) do
    [
      proj1, proj2, proj3, proj4
    ]
  end
end
