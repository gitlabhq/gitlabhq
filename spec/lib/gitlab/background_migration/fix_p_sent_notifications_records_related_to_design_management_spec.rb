# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::FixPSentNotificationsRecordsRelatedToDesignManagement, feature_category: :team_planning do
  let(:projects) { table(:projects) }
  let(:namespaces) { table(:namespaces) }
  let(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }
  let!(:p_sent_notifications) do
    partitioned_table(
      :p_sent_notifications,
      by: :partition,
      strategy: :sliding_list,
      next_partition_if: ->(_) {},
      detach_partition_if: ->(_) {}
    )
  end

  let(:group) { namespaces.create!(name: 'group', path: 'group', organization_id: organization.id) }
  let(:project_namespace) { namespaces.create!(name: 'project', path: 'project', organization_id: organization.id) }
  let(:project) do
    projects.create!(
      namespace_id: group.id,
      project_namespace_id: project_namespace.id,
      organization_id: organization.id
    )
  end

  let(:issue) do
    table(:issues).create!(
      title: 'First issue',
      iid: 1,
      namespace_id: group.id,
      work_item_type_id: 1 # Fixed ID of work_item_type `issue`
    )
  end

  let(:design) do
    table(:design_management_designs).create!(project_id: project.id, filename: 'final_v2.jpg', iid: 1)
  end

  let!(:invalid_notification1) do
    p_sent_notifications.create!(
      noteable_type: 'DesignManagement::Design',
      noteable_id: design.id,
      namespace_id: group.id,
      reply_key: SecureRandom.hex(16)
    )
  end

  let!(:invalid_notification2) do
    p_sent_notifications.create!(
      noteable_type: 'DesignManagement::Design',
      noteable_id: design.id,
      namespace_id: group.id,
      reply_key: SecureRandom.hex(16)
    )
  end

  let!(:invalid_notification3) do
    p_sent_notifications.create!(
      noteable_type: 'DesignManagement::Design',
      noteable_id: design.id,
      namespace_id: group.id,
      reply_key: SecureRandom.hex(16)
    )
  end

  let!(:invalid_notification4) do
    p_sent_notifications.create!(
      noteable_type: 'DesignManagement::Design',
      noteable_id: design.id,
      namespace_id: group.id,
      reply_key: SecureRandom.hex(16)
    )
  end

  let!(:issue_notification) do
    p_sent_notifications.create!(
      noteable_type: 'Issue',
      noteable_id: issue.id,
      namespace_id: group.id,
      reply_key: SecureRandom.hex(16)
    )
  end

  let(:migration) do
    start_id, end_id = p_sent_notifications.pick('MIN(id), MAX(id)')

    described_class.new(
      start_id: start_id,
      end_id: end_id,
      batch_table: :p_sent_notifications,
      batch_column: :id,
      sub_batch_size: 2,
      pause_ms: 0,
      job_arguments: [],
      connection: ApplicationRecord.connection
    )
  end

  describe '#up' do
    subject(:migrate) { migration.perform }

    it 'inserts records in batches' do
      expect do
        migrate
        # Only 4 design management records, other should not be updated
      end.to make_queries_matching(/UPDATE "p_sent_notifications"/, 2)
    end

    it 'sets correct namespace_id in every record' do
      expect do
        migrate
      end.to change { invalid_notification1.reload.namespace_id }.from(group.id).to(project_namespace.id).and(
        change { invalid_notification2.reload.namespace_id }.from(group.id).to(project_namespace.id)
      ).and(
        change { invalid_notification3.reload.namespace_id }.from(group.id).to(project_namespace.id)
      ).and(
        change { invalid_notification4.reload.namespace_id }.from(group.id).to(project_namespace.id)
      ).and(
        not_change { issue_notification.reload.namespace_id }.from(group.id)
      )
    end
  end
end
