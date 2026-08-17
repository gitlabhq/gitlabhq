# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillWorkItemPositionsRelativePositioningNamespaceId,
  feature_category: :team_planning do
  let(:user_ns_type) { Namespaces::UserNamespace.sti_name }
  let(:project_ns_type) { Namespaces::ProjectNamespace.sti_name }
  let(:group_type) { Group.sti_name }
  let(:organizations_table) { table(:organizations) }
  let(:namespaces_table) { table(:namespaces) }
  let(:projects_table) { table(:projects) }
  let(:issues_table) { table(:issues) }
  let(:work_item_positions_table) { table(:work_item_positions) }

  let(:work_item_type_id) { 1 }

  let!(:organization) { organizations_table.create!(name: 'org', path: 'org') }

  # --- Group project: positioning root == top-level group ---
  let!(:root_group) do
    namespaces_table.create!(name: 'root', path: 'root', type: group_type, organization_id: organization.id).tap do |n|
      n.update!(traversal_ids: [n.id])
    end
  end

  let!(:group_project_ns) do
    namespaces_table.create!(
      name: 'gp', path: 'gp', type: project_ns_type,
      parent_id: root_group.id, organization_id: organization.id
    ).tap { |n| n.update!(traversal_ids: [root_group.id, n.id]) }
  end

  let!(:group_project) do
    projects_table.create!(namespace_id: root_group.id, project_namespace_id: group_project_ns.id,
      organization_id: organization.id)
  end

  # --- Subgroup project: positioning root == top-level group (not the subgroup) ---
  let!(:subgroup) do
    namespaces_table.create!(
      name: 'sub', path: 'sub', type: group_type, parent_id: root_group.id, organization_id: organization.id
    ).tap { |n| n.update!(traversal_ids: [root_group.id, n.id]) }
  end

  let!(:subgroup_project_ns) do
    namespaces_table.create!(
      name: 'sgp', path: 'sgp', type: project_ns_type,
      parent_id: subgroup.id, organization_id: organization.id
    ).tap { |n| n.update!(traversal_ids: [root_group.id, subgroup.id, n.id]) }
  end

  let!(:subgroup_project) do
    projects_table.create!(namespace_id: subgroup.id, project_namespace_id: subgroup_project_ns.id,
      organization_id: organization.id)
  end

  # --- Personal project: positioning root == the project namespace itself (NOT the user namespace) ---
  let!(:user_namespace) do
    namespaces_table.create!(
      name: 'user', path: 'user', type: user_ns_type, organization_id: organization.id
    ).tap { |n| n.update!(traversal_ids: [n.id]) }
  end

  let!(:personal_project_ns) do
    namespaces_table.create!(
      name: 'pp', path: 'pp', type: project_ns_type,
      parent_id: user_namespace.id, organization_id: organization.id
    ).tap { |n| n.update!(traversal_ids: [user_namespace.id, n.id]) }
  end

  let!(:personal_project) do
    projects_table.create!(namespace_id: user_namespace.id, project_namespace_id: personal_project_ns.id,
      organization_id: organization.id)
  end

  # Issue creation fires the sync trigger, which upserts a work_item_positions row.
  let!(:group_issue) do
    issues_table.create!(title: 'g', project_id: group_project.id, namespace_id: group_project_ns.id,
      work_item_type_id: work_item_type_id, relative_position: 100)
  end

  let!(:subgroup_issue) do
    issues_table.create!(title: 's', project_id: subgroup_project.id, namespace_id: subgroup_project_ns.id,
      work_item_type_id: work_item_type_id, relative_position: 200)
  end

  let!(:personal_issue) do
    issues_table.create!(title: 'p', project_id: personal_project.id, namespace_id: personal_project_ns.id,
      work_item_type_id: work_item_type_id, relative_position: 300)
  end

  def positioning_ns_id(issue)
    work_item_positions_table.find_by(work_item_id: issue.id).relative_positioning_namespace_id
  end

  describe '#perform' do
    def perform_migration
      described_class.new(
        start_cursor: [work_item_positions_table.minimum(:work_item_id)],
        end_cursor: [work_item_positions_table.maximum(:work_item_id)],
        batch_table: :work_item_positions,
        batch_column: :work_item_id,
        sub_batch_size: 2,
        pause_ms: 0,
        connection: ActiveRecord::Base.connection
      ).perform
    end

    before do
      # Simulate rows that predate the column (the trigger sets it on insert).
      work_item_positions_table.update_all(relative_positioning_namespace_id: nil)
    end

    it 'backfills relative_positioning_namespace_id with the positioning root', :aggregate_failures do
      expect { perform_migration }
        .to change { work_item_positions_table.where(relative_positioning_namespace_id: nil).count }.to(0)

      expect(positioning_ns_id(group_issue)).to eq(root_group.id)
      expect(positioning_ns_id(subgroup_issue)).to eq(root_group.id)
      expect(positioning_ns_id(personal_issue)).to eq(personal_project_ns.id)
    end

    it 'is idempotent' do
      perform_migration

      expect { perform_migration }.not_to change {
        work_item_positions_table.order(:work_item_id).pluck(:relative_positioning_namespace_id)
      }
    end

    it 'overwrites a stale root, not only NULL rows' do
      work_item_positions_table
        .where(work_item_id: subgroup_issue.id)
        .update_all(relative_positioning_namespace_id: subgroup.id)

      perform_migration

      expect(positioning_ns_id(subgroup_issue)).to eq(root_group.id)
    end
  end
end
