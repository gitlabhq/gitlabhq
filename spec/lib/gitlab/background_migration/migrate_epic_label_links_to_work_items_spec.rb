# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::MigrateEpicLabelLinksToWorkItems, feature_category: :portfolio_management do
  let(:label_links) { table(:label_links) }
  let(:epics) { table(:epics) }
  let(:issues) { table(:issues) }
  let(:labels) { table(:labels) }
  let(:namespaces) { table(:namespaces) }
  let(:users) { table(:users) }
  let(:organizations) { table(:organizations) }

  let(:organization) { organizations.create!(name: 'organization', path: 'organization') }
  let(:group) { namespaces.create!(name: 'group', path: 'group', type: 'Group', organization_id: organization.id) }

  let(:user) do
    users.create!(
      username: 'test_user',
      email: 'test@example.com',
      projects_limit: 10,
      organization_id: organization.id
    )
  end

  let(:label1) { labels.create!(title: 'label1', color: '#FF0000', group_id: group.id) }
  let(:label2) { labels.create!(title: 'label2', color: '#00FF00', group_id: group.id) }
  let(:label3) { labels.create!(title: 'label3', color: '#00FF00', group_id: group.id) }

  let(:epic_work_item_type_id) { 8 }
  let!(:work_item1) do
    issues.create!(
      title: 'Issue 1',
      iid: 1,
      namespace_id: group.id,
      work_item_type_id: epic_work_item_type_id
    )
  end

  let!(:work_item2) do
    issues.create!(
      title: 'Issue 2',
      iid: 2,
      namespace_id: group.id,
      work_item_type_id: epic_work_item_type_id
    )
  end

  let!(:epic1) do
    epics.create!(
      iid: 1,
      group_id: group.id,
      author_id: user.id,
      title: 'Epic 1',
      title_html: 'Epic 1',
      issue_id: work_item1.id
    )
  end

  let!(:epic2) do
    epics.create!(
      iid: 2,
      group_id: group.id,
      author_id: user.id,
      title: 'Epic 2',
      title_html: 'Epic 2',
      issue_id: work_item2.id
    )
  end

  # A label_link exists with the same label_id for the epic and the work item
  let!(:epic1_label_link2_duplicated) do
    label_links.create!(target_type: 'Epic', target_id: epic1.id, label_id: label1.id, namespace_id: group.id)
  end

  let!(:duplicated_issue_label_link) do
    label_links.create!(target_type: 'Issue', target_id: work_item1.id, label_id: label1.id, namespace_id: group.id)
  end

  let!(:epic1_label_link2) do
    label_links.create!(target_type: 'Epic', target_id: epic1.id, label_id: label2.id, namespace_id: group.id)
  end

  let!(:epic2_label_link) do
    label_links.create!(target_type: 'Epic', target_id: epic2.id, label_id: label1.id, namespace_id: group.id)
  end

  let!(:other_issue_label_link) do
    label_links.create!(target_type: 'Issue', target_id: work_item1.id, label_id: label3.id, namespace_id: group.id)
  end

  let(:migration) do
    start_id, end_id = epics.pick('MIN(id), MAX(id)')

    described_class.new(
      start_id: start_id,
      end_id: end_id,
      batch_table: :epics,
      batch_column: :id,
      sub_batch_size: 2,
      pause_ms: 0,
      job_arguments: [],
      connection: ApplicationRecord.connection
    )
  end

  describe '#perform' do
    subject(:perform_migration) { migration.perform }

    it 'migrates epic label links to issue label links' do
      expect { perform_migration }.to change {
        label_links.where(target_type: 'Epic').count
      }.from(3).to(0)
      .and change {
        label_links.where(target_type: 'Issue').count
      }.from(2).to(4)

      expect(label_links.find_by_id(epic1_label_link2_duplicated.id)).to be_nil

      expect(label_links.find(epic1_label_link2.id)).to have_attributes(
        target_type: 'Issue',
        target_id: work_item1.id,
        label_id: label2.id
      )

      expect(label_links.find(epic2_label_link.id)).to have_attributes(
        target_type: 'Issue',
        target_id: work_item2.id,
        label_id: label1.id
      )

      expect(label_links.find(other_issue_label_link.id)).to have_attributes(
        target_type: 'Issue',
        target_id: work_item1.id,
        label_id: label3.id
      )

      expect(label_links.find(duplicated_issue_label_link.id)).to have_attributes(
        target_type: 'Issue',
        target_id: work_item1.id,
        label_id: label1.id
      )
    end
  end
end
