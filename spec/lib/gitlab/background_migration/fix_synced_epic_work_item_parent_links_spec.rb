# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::FixSyncedEpicWorkItemParentLinks, feature_category: :team_planning do
  let!(:author) { table(:users).create!(username: 'tester', projects_limit: 100) }
  let!(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }
  let!(:namespace) { table(:namespaces).create!(name: 'group 1', path: 'group-1', organization_id: organization.id) }

  let!(:project_namespace1) do
    table(:namespaces).create!(name: 'namespace 1', path: 'namespace-2', organization_id: organization.id)
  end

  let!(:project1) do
    table(:projects).create!(name: 'my test project 1', path: 'my-test-project-1', namespace_id: namespace.id,
      project_namespace_id: project_namespace1.id, organization_id: organization.id)
  end

  let!(:project_namespace2) do
    table(:namespaces).create!(name: 'namespace 2', path: 'namespace-2', organization_id: organization.id)
  end

  let!(:project2) do
    table(:projects).create!(name: 'my test project 2', path: 'my-test-project-2', namespace_id: namespace.id,
      project_namespace_id: project_namespace2.id, organization_id: organization.id)
  end

  let!(:epics) { table(:epics) }
  let!(:issues) { table(:issues) }
  let!(:epic_issues) { table(:epic_issues) }
  let!(:work_item_parent_links) { table(:work_item_parent_links) }
  let!(:epic_work_item_type_id) { table(:work_item_types).where(name: 'Epic').first.id }
  let!(:issue_work_item_type_id) { table(:work_item_types).where(name: 'Issue').first.id }

  before do
    (1..3).each do |i|
      epic_work_item = issues.create!(
        iid: i, namespace_id: namespace.id, title: "epic #{i}", title_html: "epic #{i}",
        work_item_type_id: epic_work_item_type_id
      )
      legacy_epic = epics.create!(
        iid: i, group_id: namespace.id, title: "epic #{i}", title_html: "epic #{i}",
        issue_id: epic_work_item.id, author_id: author.id
      )

      other_epic_work_item = issues.create!(
        iid: i + 100, namespace_id: namespace.id, title: "epic #{i + 100}", title_html: "epic #{i + 100}",
        work_item_type_id: epic_work_item_type_id
      )
      other_legacy_epic = epics.create!(
        iid: i + 100, group_id: namespace.id, title: "epic #{i + 100}", title_html: "epic #{i + 100}",
        issue_id: other_epic_work_item.id, author_id: author.id
      )

      # not affected: work_item_parent_links where `work_item_id` and `namespace_id` are correct
      2.times do
        issues.create!(project_id: project1.id, title: "initial",
          work_item_type_id: issue_work_item_type_id, namespace_id: project_namespace1.id)

        moved_issue = issues.create!(project_id: project2.id, title: "moved",
          work_item_type_id: issue_work_item_type_id, namespace_id: project2.project_namespace_id)

        epic_issues.create!(epic_id: legacy_epic.id, issue_id: moved_issue.id)
        work_item_parent_links.create!(
          work_item_id: moved_issue.id, work_item_parent_id: epic_work_item.id,
          namespace_id: project2.project_namespace_id
        )
      end

      # Orphaned work_item_parent_links
      # work_item_parent_links where `work_item_id` and `namespace_id` did not get updated correctly
      2.times do
        initial_issue = issues.create!(project_id: project1.id, title: "initial",
          work_item_type_id: issue_work_item_type_id, namespace_id: project1.project_namespace_id)

        moved_issue = issues.create!(project_id: project2.id, title: "moved",
          work_item_type_id: issue_work_item_type_id, namespace_id: project2.project_namespace_id)

        epic_issues.create!(epic_id: legacy_epic.id, issue_id: moved_issue.id)
        work_item_parent_links.create!(
          work_item_id: initial_issue.id, work_item_parent_id: epic_work_item.id,
          namespace_id: project1.project_namespace_id
        )
      end

      # epic_issues where the work_item_parent_link is missing
      (1..2).each do |j|
        issues.create!(project_id: project1.id, title: "initial",
          work_item_type_id: issue_work_item_type_id, namespace_id: project1.project_namespace_id)

        moved_issue = issues.create!(project_id: project2.id, title: "moved",
          work_item_type_id: issue_work_item_type_id, namespace_id: project2.project_namespace_id)

        epic_issues.create!(epic_id: legacy_epic.id, issue_id: moved_issue.id, relative_position: i * j)
      end

      # epic_issues where the epic_id, issue_id, and namespace_id changed
      2.times do
        initial_issue = issues.create!(project_id: project1.id, title: "initial",
          work_item_type_id: issue_work_item_type_id, namespace_id: project1.project_namespace_id)

        moved_issue = issues.create!(project_id: project2.id, title: "moved",
          work_item_type_id: issue_work_item_type_id, namespace_id: project2.project_namespace_id)

        epic_issues.create!(epic_id: other_legacy_epic.id, issue_id: moved_issue.id)
        work_item_parent_links.create!(
          work_item_id: initial_issue.id, work_item_parent_id: epic_work_item.id,
          namespace_id: project1.project_namespace_id
        )
      end

      # epic work item without a legacy epic that should not be affected
      epic_work_item_without_legacy_epic = issues.create!(
        namespace_id: namespace.id, title: "epic #{i + 10}", title_html: "epic #{i + 10}",
        work_item_type_id: epic_work_item_type_id
      )

      2.times do
        issue = issues.create!(project_id: project1.id, title: "some issue",
          work_item_type_id: issue_work_item_type_id, namespace_id: project1.project_namespace_id)

        work_item_parent_links.create!(
          work_item_id: issue.id, work_item_parent_id: epic_work_item_without_legacy_epic.id,
          namespace_id: project1.project_namespace_id
        )
      end

      # epic to epic hierarchy to make sure it doesn't get deleted
      (1..2).each do |j|
        child_epic_work_item = issues.create!(
          namespace_id: namespace.id, title: "epic #{i + 100}", title_html: "epic #{i}",
          work_item_type_id: epic_work_item_type_id, iid:  (500 * j) + i
        )
        epics.create!(
          group_id: namespace.id, title: "epic #{i + 100}", title_html: "epic #{i}",
          issue_id: child_epic_work_item.id, author_id: author.id, iid: child_epic_work_item.iid,
          parent_id: legacy_epic.id
        )

        work_item_parent_links.create!(
          work_item_id: child_epic_work_item.id, work_item_parent_id: epic_work_item.id,
          namespace_id: namespace.id
        )
      end
    end
  end

  RSpec::Matchers.define :have_synced_parent_links do
    match do |epic_issue|
      parent_epic = epics.find(epic_issue.epic_id)
      parent_work_item = issues.find(parent_epic.issue_id)
      child_work_item = issues.find(epic_issue.issue_id)

      work_item_parent_links.exists?(
        work_item_parent_id: parent_work_item.id,
        work_item_id: child_work_item.id,
        namespace_id: child_work_item.namespace_id,
        relative_position: epic_issue.relative_position
      )
    end
  end

  RSpec::Matchers.define :have_synced_epic_issues do
    match do |parent_link|
      epic = epics.find_by_issue_id(parent_link.work_item_parent_id)

      epic_issues.exists?(
        epic_id: epic.id,
        issue_id: parent_link.work_item_id,
        relative_position: parent_link.relative_position
      )
    end
  end

  context 'when backfilling', :aggregate_failures do
    let!(:start_id) { epics.minimum(:id) }
    let!(:end_id) { epics.maximum(:id) }

    let!(:migration) do
      described_class.new(
        start_id: start_id,
        end_id: end_id,
        batch_table: :epics,
        batch_column: :id,
        job_arguments: [],
        sub_batch_size: 2,
        pause_ms: 2,
        connection: ::ApplicationRecord.connection
      )
    end

    let(:issue_parent_links_with_legacy_epics) do
      work_item_parent_links
        .joins('JOIN epics ON epics.issue_id = work_item_parent_links.work_item_parent_id')
        .joins('JOIN issues ON work_item_parent_links.work_item_id = issues.id')
        .where(issues: { work_item_type_id: issue_work_item_type_id })
    end

    let(:issue_parent_links_without_legacy_epics) do
      work_item_parent_links.joins('LEFT JOIN epics ON epics.issue_id = work_item_parent_links.work_item_parent_id')
        .joins('JOIN issues ON work_item_parent_links.work_item_id = issues.id')
        .where(epics: { id: nil })
        .where(issues: { work_item_type_id: issue_work_item_type_id })
    end

    let(:epic_parent_links) do
      work_item_parent_links
        .joins('JOIN issues ON work_item_parent_links.work_item_id = issues.id')
        .where(issues: { work_item_type_id: epic_work_item_type_id })
    end

    it 'fixes the records', :aggregate_failures do
      # We create 6 parent links that did not have a corresponding epic_issues record
      expect { migration.perform }
        .to change { issue_parent_links_with_legacy_epics.count }.from(18).to(24)
        .and not_change { epic_issues.count }
        .and not_change { issue_parent_links_without_legacy_epics.count }
        .and not_change { epic_parent_links.count }

      expect(epic_issues.count).to eq(issue_parent_links_with_legacy_epics.count)

      expect(epic_issues.all).to all(have_synced_parent_links)
      expect(issue_parent_links_with_legacy_epics).to all(have_synced_epic_issues)
    end
  end
end
