# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::RemoveProjectGroupLinkWithMissingGroups, :migration,
  feature_category: :subgroups, schema: 20230206172702 do
  let(:projects) { table(:projects) }
  let(:namespaces) { table(:namespaces) }
  let(:project_group_links) { table(:project_group_links) }

  let!(:group) do
    namespaces.create!(
      name: 'Group0', type: 'Group', path: 'space0'
    )
  end

  let!(:group_1) do
    namespaces.create!(
      name: 'Group1', type: 'Group', path: 'space1'
    )
  end

  let!(:group_2) do
    namespaces.create!(
      name: 'Group2', type: 'Group', path: 'space2'
    )
  end

  let!(:group_3) do
    namespaces.create!(
      name: 'Group3', type: 'Group', path: 'space3'
    )
  end

  let!(:project_namespace_1) do
    namespaces.create!(
      name: 'project_1', path: 'project_1', type: 'Project'
    )
  end

  let!(:project_namespace_2) do
    namespaces.create!(
      name: 'project_2', path: 'project_2', type: 'Project'
    )
  end

  let!(:project_namespace_3) do
    namespaces.create!(
      name: 'project_3', path: 'project_3', type: 'Project'
    )
  end

  let!(:project_1) do
    projects.create!(
      name: 'project_1', path: 'project_1', namespace_id: group.id, project_namespace_id: project_namespace_1.id
    )
  end

  let!(:project_2) do
    projects.create!(
      name: 'project_2', path: 'project_2', namespace_id: group.id, project_namespace_id: project_namespace_2.id
    )
  end

  let!(:project_3) do
    projects.create!(
      name: 'project_3', path: 'project_3', namespace_id: group.id, project_namespace_id: project_namespace_3.id
    )
  end

  let!(:project_group_link_1) do
    project_group_links.create!(
      project_id: project_1.id, group_id: group_1.id, group_access: Gitlab::Access::DEVELOPER
    )
  end

  let!(:project_group_link_2) do
    project_group_links.create!(
      project_id: project_2.id, group_id: group_2.id, group_access: Gitlab::Access::DEVELOPER
    )
  end

  let!(:project_group_link_3) do
    project_group_links.create!(
      project_id: project_3.id, group_id: group_3.id, group_access: Gitlab::Access::DEVELOPER
    )
  end

  let!(:project_group_link_4) do
    project_group_links.create!(
      project_id: project_3.id, group_id: group_2.id, group_access: Gitlab::Access::DEVELOPER
    )
  end

  subject do
    described_class.new(
      start_id: project_group_link_1.id,
      end_id: project_group_link_4.id,
      batch_table: :project_group_links,
      batch_column: :id,
      sub_batch_size: 1,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    ).perform
  end

  it 'removes the `project_group_links` records whose associated group does not exist anymore' do
    group_2.delete

    # Schema is fixed to `20230206172702` on this spec.
    # This expectation is needed to make sure that the orphaned records are indeed deleted via the migration
    # and not via the foreign_key relationship introduced after `20230206172702`, in `20230207002330`
    expect(project_group_links.count).to eq(4)

    expect { subject }
      .to change { project_group_links.count }.from(4).to(2)
      .and change {
        project_group_links.where(project_id: project_2.id, group_id: group_2.id).present?
      }.from(true).to(false)
      .and change {
        project_group_links.where(project_id: project_3.id, group_id: group_2.id).present?
      }.from(true).to(false)
  end
end
