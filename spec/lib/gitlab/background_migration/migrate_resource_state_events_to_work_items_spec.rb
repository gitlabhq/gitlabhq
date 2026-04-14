# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::MigrateResourceStateEventsToWorkItems, feature_category: :portfolio_management do
  let(:resource_state_events) { table(:resource_state_events) }
  let(:epics) { table(:epics) }
  let(:issues) { table(:issues) }
  let(:namespaces) { table(:namespaces) }
  let(:users) { table(:users) }
  let(:organizations) { table(:organizations) }

  let(:organization) { organizations.create!(name: 'organization', path: 'organization') }
  let(:group) do
    namespaces.create!(name: 'group', path: 'group', type: 'Group', organization_id: organization.id)
  end

  let(:user) do
    users.create!(
      username: 'test_user',
      email: 'test@example.com',
      projects_limit: 10,
      organization_id: organization.id
    )
  end

  let(:epic_work_item_type_id) { 8 }

  let!(:work_item1) do
    issues.create!(
      title: 'Work Item 1',
      id: 1,
      iid: 1,
      namespace_id: group.id,
      work_item_type_id: epic_work_item_type_id
    )
  end

  let!(:work_item2) do
    issues.create!(
      title: 'Work Item 2',
      id: 2,
      iid: 2,
      namespace_id: group.id,
      work_item_type_id: epic_work_item_type_id
    )
  end

  let!(:epic1) do
    epics.create!(
      id: 3,
      iid: 3,
      group_id: group.id,
      author_id: user.id,
      title: 'Epic 1',
      title_html: 'Epic 1',
      issue_id: work_item1.id
    )
  end

  let!(:epic2) do
    epics.create!(
      id: 4,
      iid: 4,
      group_id: group.id,
      author_id: user.id,
      title: 'Epic 2',
      title_html: 'Epic 2',
      issue_id: work_item2.id
    )
  end

  # A unique resource_state_event for epic1
  let!(:epic1_state_event_unique) do
    resource_state_events.create!(
      epic_id: epic1.id,
      user_id: user.id,
      state: 1,
      namespace_id: group.id,
      created_at: 3.hours.ago
    )
  end

  # A resource_state_event for epic2
  let!(:epic2_state_event) do
    resource_state_events.create!(
      epic_id: epic2.id,
      user_id: user.id,
      state: 2,
      namespace_id: group.id,
      created_at: 4.hours.ago
    )
  end

  # A resource_state_event already pointing to a work item (should be untouched)
  let!(:existing_issue_state_event) do
    resource_state_events.create!(
      issue_id: work_item2.id,
      user_id: user.id,
      state: 1,
      namespace_id: group.id,
      created_at: 5.hours.ago
    )
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

    it 'migrates epic resource_state_events to work item resource_state_events' do
      expect { perform_migration }.to change {
        resource_state_events.where.not(epic_id: nil).count
      }.from(2).to(0)
        .and change {
          resource_state_events.where.not(issue_id: nil).count
        }.from(1).to(3)

      # The unique epic1 event should be migrated to work_item1
      expect(resource_state_events.find(epic1_state_event_unique.id)).to have_attributes(
        epic_id: nil,
        issue_id: work_item1.id,
        user_id: user.id,
        state: 1
      )

      # The epic2 event should be migrated to work_item2
      expect(resource_state_events.find(epic2_state_event.id)).to have_attributes(
        epic_id: nil,
        issue_id: work_item2.id,
        user_id: user.id,
        state: 2
      )

      # The existing issue state event should be untouched
      expect(resource_state_events.find(existing_issue_state_event.id)).to have_attributes(
        epic_id: nil,
        issue_id: work_item2.id,
        user_id: user.id,
        state: 1
      )
    end
  end
end
