# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillEpicIssuesIntoWorkItemParentLinks, feature_category: :team_planning do
  let(:author) { table(:users).create!(username: 'tester', projects_limit: 100) }
  let(:epic_issues) { table(:epic_issues) }
  let(:work_item_parent_links) { table(:work_item_parent_links) }
  let(:group1) { table(:namespaces).create!(name: 'my test group 1', path: 'my-test-group1', type: 'Group') }
  let(:group2) { table(:namespaces).create!(name: 'my test group 2', path: 'my-test-group2', type: 'Group') }
  let(:epics) { table(:epics) }
  let(:issues) { table(:issues) }
  let(:start_id) { epic_issues.minimum(:id) }
  let(:end_id) { epic_issues.maximum(:id) }
  let(:batch_column) { 'id' }
  let(:epic_work_item_type_enum) { 7 }
  let(:epic_work_item_type_id) { table(:work_item_types).where(base_type: epic_work_item_type_enum).first.id }
  let(:issue_work_item_type_enum) { 0 }
  let(:issue_work_item_type_id) { table(:work_item_types).where(base_type: issue_work_item_type_enum).first.id }
  let!(:issue_epic1) do
    issues.create!(
      title: 'Epic 1', namespace_id: group1.id, author_id: author.id, work_item_type_id: epic_work_item_type_id
    )
  end

  let!(:issue_epic2) do
    issues.create!(
      title: 'Epic 2', namespace_id: group1.id, author_id: author.id, work_item_type_id: epic_work_item_type_id
    )
  end

  let!(:epic1) do
    epics.create!(
      title: 'test epic1',
      title_html: 'Epic 1',
      group_id: group1.id,
      author_id: author.id,
      iid: 1,
      issue_id: issue_epic1.id
    )
  end

  let!(:epic2) do
    epics.create!(
      title: 'test epic2',
      title_html: 'Epic 2',
      group_id: group1.id,
      author_id: author.id,
      iid: 2,
      issue_id: issue_epic2.id
    )
  end

  let(:issues1) do
    (1..5).map do |i|
      issues.create!(
        title: "Issue #{i}", namespace_id: group1.id, author_id: author.id, work_item_type_id: issue_work_item_type_id
      )
    end
  end

  let(:issues2) do
    (1..5).map do |i|
      issues.create!(
        title: "Issue #{i}", namespace_id: group1.id, author_id: author.id, work_item_type_id: issue_work_item_type_id
      )
    end
  end

  let(:group2_issue_epic) do
    issues.create!(
      title: 'Epic 1',
      namespace_id: group2.id,
      author_id: author.id,
      work_item_type_id: epic_work_item_type_id
    )
  end

  let!(:group2_epic_issue) do
    issue = issues.create!(
      title: 'Issue',
      namespace_id: group2.id,
      author_id: author.id,
      work_item_type_id: issue_work_item_type_id
    )
    epic = epics.create!(
      title: 'test epic1',
      title_html: 'Epic 1',
      group_id: group2.id,
      author_id: author.id,
      iid: 1,
      issue_id: group2_issue_epic.id
    )
    epic_issues.create!(epic_id: epic.id, issue_id: issue.id, relative_position: 1)
  end

  let(:migration) do
    described_class.new(
      start_id: start_id,
      end_id: end_id,
      batch_table: batch_table,
      batch_column: batch_column,
      job_arguments: job_arguments,
      sub_batch_size: 2,
      pause_ms: 2,
      connection: ::ApplicationRecord.connection
    )
  end

  before do
    issues1.each_with_index do |issue, index|
      epic_issues.create!(epic_id: epic1.id, issue_id: issue.id, relative_position: index)
    end

    issues2.each_with_index do |issue, index|
      epic_issues.create!(epic_id: epic2.id, issue_id: issue.id, relative_position: index)
    end
  end

  RSpec::Matchers.define :have_synced_work_item_epic_issue_link do
    match do |epic_issue|
      parent_epic = epics.find(epic_issue.epic_id)
      parent_work_item = issues.find(parent_epic.issue_id)
      child_work_item = issues.find(epic_issue.issue_id)

      work_item_parent_links.exists?(
        work_item_parent_id: parent_work_item.id,
        work_item_id: child_work_item.id,
        relative_position: epic_issue.relative_position,
        namespace_id: parent_work_item.namespace_id
      )
    end
  end

  context 'when epic_issues table is used to go through all records' do
    let(:batch_table) { 'epic_issues' }

    context 'when no group id is provided' do
      let(:job_arguments) { [nil] }

      it 'backfills all records' do
        expect do
          migration.perform
        end.to change { work_item_parent_links.count }.by(11) # 10 records for group 1 and 1 record for group 2

        expect(epic_issues.all).to all(have_synced_work_item_epic_issue_link)
      end

      it 'upserts records if any of them already exist' do
        existing_epic_issue = epic_issues.first
        existing_epic = epics.find(existing_epic_issue.epic_id)
        existing_work_item_parent_link = work_item_parent_links.create!(
          work_item_parent_id: existing_epic.issue_id,
          work_item_id: existing_epic_issue.issue_id,
          relative_position: -100
        )

        expect do
          migration.perform
        end.to change { work_item_parent_links.count }.by(10).and( # only 10 as 1 already exists
          change { existing_work_item_parent_link.reload.relative_position }
            .from(-100)
            .to(existing_epic_issue.relative_position)
        )
      end
    end

    context 'when a group id is provided' do
      let(:job_arguments) { [group2.id] }

      it 'raises an error' do
        expect do
          migration.perform
        end.to raise_error('when group_id is provided, use `epics` as batch_table and `iid` as batch_column')
      end
    end
  end

  context 'when epics table is used to go through all records' do
    let(:batch_table) { 'epics' }
    let(:batch_column) { 'iid' }
    let(:start_id) { epics.minimum(:iid) }
    let(:end_id) { epics.maximum(:iid) }

    context 'when a group id is provided' do
      let(:job_arguments) { [group2.id] }

      it 'backfills records only for the specified group' do
        expect do
          migration.perform
        end.to change { work_item_parent_links.count }.by(1) # Only 1 record for group 2

        expect(group2_epic_issue).to have_synced_work_item_epic_issue_link
      end
    end

    context 'when no group_id is provided' do
      let(:job_arguments) { [nil] }

      it 'raises an error' do
        expect do
          migration.perform
        end.to raise_error('use `epic_issues` as batch_table when no group_id is provided')
      end
    end

    context 'when batch column is not iid' do
      let(:job_arguments) { [group2.id] }
      let(:batch_column) { 'id' }

      it 'raises an error' do
        expect do
          migration.perform
        end.to raise_error('when group_id is provided, use `epics` as batch_table and `iid` as batch_column')
      end
    end
  end
end
