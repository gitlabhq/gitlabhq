# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::MigrateEpicEventsToWorkItems, feature_category: :portfolio_management do
  let(:events) { table(:events) }
  let(:epics) { table(:epics) }
  let(:issues) { table(:issues) }
  let(:namespaces) { table(:namespaces) }
  let(:users) { table(:users) }
  let(:organizations) { table(:organizations) }

  let(:organization) { organizations.create!(name: 'organization', path: 'organization') }
  let(:group) { namespaces.create!(name: 'group', path: 'group', type: 'Group', organization_id: organization.id) }

  let(:user1) do
    users.create!(
      username: 'user1',
      email: 'user1@example.com',
      projects_limit: 10,
      organization_id: organization.id
    )
  end

  let(:user2) do
    users.create!(
      username: 'user2',
      email: 'user2@example.com',
      projects_limit: 10,
      organization_id: organization.id
    )
  end

  let(:epic_work_item_type_id) { 8 }

  let!(:work_item1) do
    issues.create!(
      title: 'Epic Work Item 1',
      iid: 1,
      namespace_id: group.id,
      work_item_type_id: epic_work_item_type_id
    )
  end

  let!(:work_item2) do
    issues.create!(
      title: 'Epic Work Item 2',
      iid: 2,
      namespace_id: group.id,
      work_item_type_id: epic_work_item_type_id
    )
  end

  let!(:epic1) do
    epics.create!(
      iid: 1,
      group_id: group.id,
      author_id: user1.id,
      title: 'Epic 1',
      title_html: 'Epic 1',
      issue_id: work_item1.id
    )
  end

  let!(:epic2) do
    epics.create!(
      iid: 2,
      group_id: group.id,
      author_id: user1.id,
      title: 'Epic 2',
      title_html: 'Epic 2',
      issue_id: work_item2.id
    )
  end

  let!(:epic1_closed_event) do
    events.create!(
      target_type: 'Epic',
      target_id: epic1.id,
      group_id: group.id,
      author_id: user2.id,
      action: 3, # closed
      created_at: Time.current + 1.hour,
      updated_at: Time.current + 1.hour
    )
  end

  let!(:epic2_created_event) do
    events.create!(
      target_type: 'Epic',
      target_id: epic2.id,
      group_id: group.id,
      author_id: user1.id,
      action: 1, # created
      created_at: Time.current,
      updated_at: Time.current
    )
  end

  let!(:existing_work_item_event) do
    events.create!(
      target_type: 'WorkItem',
      target_id: work_item2.id,
      group_id: group.id,
      author_id: user2.id,
      action: 4, # reopened
      created_at: Time.current,
      updated_at: Time.current
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

    it 'migrates epic events to work item events', :aggregate_failures do
      expect { perform_migration }.to change {
        events.where(target_type: 'Epic').count
      }.from(2).to(0)
      .and change {
        events.where(target_type: 'WorkItem').count
      }.from(1).to(3)

      expect(events.find(epic1_closed_event.id)).to have_attributes(
        target_type: 'WorkItem',
        target_id: work_item1.id,
        action: 3,
        author_id: user2.id
      )

      expect(events.find(epic2_created_event.id)).to have_attributes(
        target_type: 'WorkItem',
        target_id: work_item2.id,
        action: 1,
        author_id: user1.id
      )

      expect(events.find(existing_work_item_event.id)).to have_attributes(
        target_type: 'WorkItem',
        target_id: work_item2.id,
        action: 4
      )
    end
  end
end
