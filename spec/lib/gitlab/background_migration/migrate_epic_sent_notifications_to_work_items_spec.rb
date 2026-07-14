# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::MigrateEpicSentNotificationsToWorkItems, feature_category: :portfolio_management do
  let(:sent_notifications) do
    partitioned_table(
      :p_sent_notifications,
      by: :partition,
      strategy: :sliding_list,
      next_partition_if: ->(_) {},
      detach_partition_if: ->(_) {}
    )
  end

  let(:epics) { table(:epics) }
  let(:issues) { table(:issues) }
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

  let!(:epic1_sn) do
    sent_notifications.create!(
      noteable_type: 'Epic',
      noteable_id: epic1.id,
      reply_key: 'aaaa',
      recipient_id: user.id,
      namespace_id: group.id
    )
  end

  let!(:epic2_sn) do
    sent_notifications.create!(
      noteable_type: 'Epic',
      noteable_id: epic2.id,
      reply_key: 'bbbb',
      recipient_id: user.id,
      namespace_id: group.id
    )
  end

  let!(:other_issue_sn) do
    sent_notifications.create!(
      noteable_type: 'Issue',
      noteable_id: work_item1.id,
      reply_key: 'ccccc',
      recipient_id: user.id,
      namespace_id: group.id
    )
  end

  let(:migration) do
    described_class.new(
      start_id: epics.minimum(:id),
      end_id: epics.maximum(:id),
      batch_table: :epics,
      batch_column: :id,
      sub_batch_size: 10,
      pause_ms: 0,
      job_arguments: [],
      connection: ApplicationRecord.connection
    )
  end

  describe '#perform' do
    subject(:perform_migration) { migration.perform }

    it 'migrates epic sent_notifications to point to the corresponding work item' do
      expect { perform_migration }.to change {
        sent_notifications.where(noteable_type: 'Epic').count
      }.from(2).to(0)
       .and change {
         sent_notifications.where(noteable_type: 'Issue').count
       }.from(1).to(3)
    end

    it 'updates epic1 sent_notification to point to work_item1' do
      perform_migration

      expect(sent_notifications.find(epic1_sn.id)).to have_attributes(
        noteable_type: 'Issue',
        noteable_id: work_item1.id
      )
    end

    it 'updates epic2 sent_notification to point to work_item2' do
      perform_migration

      expect(sent_notifications.find(epic2_sn.id)).to have_attributes(
        noteable_type: 'Issue',
        noteable_id: work_item2.id
      )
    end

    it 'does not modify existing Issue sent_notifications' do
      perform_migration

      expect(sent_notifications.find(other_issue_sn.id)).to have_attributes(
        noteable_type: 'Issue',
        noteable_id: work_item1.id
      )
    end
  end
end
