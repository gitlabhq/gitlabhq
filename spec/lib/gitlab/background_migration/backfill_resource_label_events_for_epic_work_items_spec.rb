# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillResourceLabelEventsForEpicWorkItems,
  feature_category: :portfolio_management do
  let(:resource_label_events) { table(:resource_label_events) }
  let(:epics) { table(:epics) }
  let(:issues) { table(:issues) }
  let(:labels) { table(:labels) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }

  let(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }
  let(:group) { namespaces.create!(name: 'group', path: 'group', type: 'Group', organization_id: organization.id) }

  let(:user) do
    table(:users).create!(
      username: 'test_user',
      email: 'test@example.com',
      projects_limit: 10,
      organization_id: organization.id
    )
  end

  let(:project) do
    projects.create!(
      name: 'project',
      path: 'project',
      namespace_id: group.id,
      project_namespace_id: namespaces.create!(name: 'project', path: 'project', organization_id: organization.id).id,
      organization_id: organization.id
    )
  end

  let(:label) { labels.create!(title: 'label1', color: '#FF0000', group_id: group.id) }

  let(:epic_work_item_type_id) { 8 }

  let!(:work_item1) do
    issues.create!(
      title: 'Work Item 1',
      iid: 1,
      namespace_id: group.id,
      work_item_type_id: epic_work_item_type_id
    )
  end

  let!(:work_item2) do
    issues.create!(
      title: 'Work Item 2',
      iid: 2,
      namespace_id: group.id,
      work_item_type_id: epic_work_item_type_id
    )
  end

  let!(:regular_issue) do
    issues.create!(
      title: 'Regular Issue',
      iid: 3,
      namespace_id: group.id,
      project_id: project.id,
      work_item_type_id: 0
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

  let!(:event_for_epic1) do
    resource_label_events.create!(
      action: 1,
      epic_id: epic1.id,
      label_id: label.id,
      user_id: user.id,
      namespace_id: group.id
    )
  end

  let!(:event_for_epic2) do
    resource_label_events.create!(
      action: 1,
      epic_id: epic2.id,
      label_id: label.id,
      user_id: user.id,
      namespace_id: group.id
    )
  end

  let!(:event_for_issue) do
    resource_label_events.create!(
      action: 1,
      issue_id: regular_issue.id,
      label_id: label.id,
      user_id: user.id,
      namespace_id: group.id
    )
  end

  let(:migration) do
    described_class.new(
      batch_table: :epics,
      batch_column: :id,
      sub_batch_size: 2,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    )
  end

  describe '#perform' do
    subject(:perform_migration) { migration.perform }

    context 'when resource_label_events has epic_id' do
      it 'backfills issue_id for resource_label_events with epic_id' do
        expect(resource_label_events.find(event_for_epic1.id).issue_id).to be_nil
        expect(resource_label_events.find(event_for_epic2.id).issue_id).to be_nil

        perform_migration

        expect(resource_label_events.find(event_for_epic1.id)).to have_attributes(
          issue_id: work_item1.id,
          epic_id: nil
        )

        expect(resource_label_events.find(event_for_epic2.id)).to have_attributes(
          issue_id: work_item2.id,
          epic_id: nil
        )
      end
    end

    context 'when resource_label_events has no epic_id' do
      it 'does not modify events without epic_id' do
        perform_migration

        expect(resource_label_events.find(event_for_issue.id)).to have_attributes(
          issue_id: regular_issue.id,
          epic_id: nil
        )
      end
    end
  end
end
