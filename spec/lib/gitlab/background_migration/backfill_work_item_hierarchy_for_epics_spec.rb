# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillWorkItemHierarchyForEpics, feature_category: :team_planning do
  let!(:epic_type_id) { table(:work_item_types).find_by(base_type: 7).id }
  let!(:author) { table(:users).create!(username: 'tester', projects_limit: 100) }
  let!(:namespace) { table(:namespaces).create!(name: 'my test group1', path: 'my-test-group1') }

  let(:epics) { table(:epics) }
  let(:issues) { table(:issues) }
  let(:parent_links) { table(:work_item_parent_links) }
  let(:start_id) { epics.minimum(:id) }
  let(:end_id) { epics.maximum(:id) }
  let(:now) { Time.current }

  # Prevents false positives. It creates one work item without an associated legacy epic
  # to make sure all work items and legacy epics global ids are different.
  let(:work_item) do
    issues.create!(
      author_id: author.id,
      work_item_type_id: epic_type_id,
      namespace_id: namespace.id,
      lock_version: 100,
      title: 'First work item'
    )
  end

  # Parent epics
  let!(:parent_epic_1) { create_epic_with_work_item(title: 'Epic 1', iid: 1) }
  let!(:parent_epic_2) { create_epic_with_work_item(title: 'Epic 2', iid: 2) }
  let!(:parent_epic_3) { create_epic_with_work_item(title: 'Epic 3', iid: 3) }
  let!(:parent_epic_4) { create_epic_with_work_item(title: 'Epic 4', iid: 4) }
  # Target epics
  let!(:child_epic_1) do
    create_epic_with_work_item(title: 'Epic 5', iid: 5, parent_id: parent_epic_1.id, relative_position: 1)
  end

  let!(:child_epic_2) do
    create_epic_with_work_item(title: 'Epic 6', iid: 6, parent_id: parent_epic_3.id, relative_position: 2)
  end

  # Already in sync but with outdated relative position
  let!(:child_epic_3) do
    epic =
      create_epic_with_work_item(title: 'Epic 7', iid: 7, parent_id: parent_epic_3.id, relative_position: 3)

    parent_links.create!(
      work_item_id: epic.issue_id,
      work_item_parent_id: parent_epic_3.issue_id,
      relative_position: 4,
      created_at: now,
      updated_at: now
    )
  end

  let!(:child_epic_4) do
    create_epic_with_work_item(title: 'Epic 8', iid: 8, parent_id: parent_epic_4.id, relative_position: 10)
  end

  let!(:child_epic_5) do
    create_epic_with_work_item(title: 'Epic 9', iid: 9, parent_id: child_epic_4.id, relative_position: 20)
  end

  let!(:epic_without_parent) { create_epic_with_work_item(title: 'Epic 10', iid: 10) }

  subject(:migration) do
    described_class.new(
      start_id: start_id,
      end_id: end_id,
      batch_table: :epics,
      batch_column: :id,
      sub_batch_size: 2,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    )
  end

  RSpec::Matchers.define :have_synced_parent_link do
    match do |epic|
      parent_epic = epics.find(epic.parent_id)
      parent_work_item = issues.find(parent_epic.issue_id)
      child_work_item = issues.find(epic.issue_id)

      parent_links.find_by(
        work_item_parent_id: parent_work_item.id,
        work_item_id: child_work_item.id,
        relative_position: epic.relative_position,
        namespace_id: parent_work_item.namespace_id
      ).present?
    end
  end

  it 'backfills data correctly' do
    expect do
      migration.perform
    end.to change { parent_links.count }.from(1).to(5)

    expect(epics.where.not(parent_id: nil)).to all(have_synced_parent_link)
  end

  def create_epic_with_work_item(iid:, title:, parent_id: nil, relative_position: nil)
    wi = issues.create!(
      iid: iid,
      author_id: author.id,
      work_item_type_id: epic_type_id,
      namespace_id: namespace.id,
      lock_version: 1,
      title: title
    )

    epics.create!(
      iid: iid,
      title: title,
      title_html: title,
      group_id: namespace.id,
      author_id: author.id,
      issue_id: wi.id,
      parent_id: parent_id,
      relative_position: relative_position
    )
  end
end
