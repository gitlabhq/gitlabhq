# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillNewAuditEventTables, feature_category: :audit_events do
  let(:audit_events_table) { partitioned_table(:audit_events) }
  let(:project_audit_events_table) { partitioned_table(:project_audit_events) }
  let(:group_audit_events_table) { partitioned_table(:group_audit_events) }
  let(:user_audit_events_table) { partitioned_table(:user_audit_events) }
  let(:instance_audit_events_table) { partitioned_table(:instance_audit_events) }

  let!(:project_audit_event) do
    audit_events_table.create!(
      id: 1,
      entity_type: 'Project',
      entity_id: 1,
      author_id: 1,
      target_id: 1,
      details: 'project details',
      ip_address: '127.0.0.1',
      author_name: 'project author',
      entity_path: 'project/path',
      target_details: 'target details',
      target_type: 'target type',
      created_at: Time.parse("2024-07-04 05:25:54.332355000 +0000")
    )
  end

  let!(:group_audit_event) do
    audit_events_table.create!(
      id: 2,
      entity_type: 'Group',
      entity_id: 2,
      author_id: 2,
      target_id: 2,
      details: 'group details',
      ip_address: '127.0.0.2',
      author_name: 'group author',
      entity_path: 'group/path',
      target_details: 'group target details',
      target_type: 'group target type',
      created_at: Time.parse("2024-07-04 05:25:54.332355000 +0000")
    )
  end

  let!(:user_audit_event) do
    audit_events_table.create!(
      id: 3,
      entity_type: 'User',
      entity_id: 3,
      author_id: 3,
      target_id: 3,
      details: 'user details',
      ip_address: '127.0.0.3',
      author_name: 'user author',
      entity_path: 'user/path',
      target_details: 'user target details',
      target_type: 'user target type',
      created_at: Time.parse("2024-07-04 05:25:54.332355000 +0000")
    )
  end

  let!(:instance_audit_event) do
    audit_events_table.create!(
      id: 4,
      entity_type: 'Gitlab::Audit::InstanceScope',
      entity_id: 4,
      author_id: 4,
      target_id: 4,
      details: 'instance details',
      ip_address: '127.0.0.4',
      author_name: 'instance author',
      entity_path: 'instance/path',
      target_details: 'instance target details',
      target_type: 'instance target type',
      created_at: Time.parse("2024-07-04 05:25:54.332355000 +0000")
    )
  end

  let(:start_id) { project_audit_event.id }
  let(:end_id) { instance_audit_event.id }

  subject(:perform_migration) do
    described_class.new(
      start_id: start_id,
      end_id: end_id,
      batch_table: :audit_events,
      batch_column: :id,
      sub_batch_size: 2,
      pause_ms: 0,
      connection: ActiveRecord::Base.connection
    ).perform
  end

  it 'correctly migrates audit events into new tables', :aggregate_failures do
    expect(ActiveRecord::QueryRecorder.new { perform_migration }.count).to eq(9)

    project_event = project_audit_events_table.find_by_id(project_audit_event.id)

    expect(project_event).to have_attributes(
      id: project_audit_event.id,
      created_at: project_audit_event.created_at,
      project_id: project_audit_event.entity_id,
      author_id: project_audit_event.author_id,
      target_id: project_audit_event.target_id,
      details: project_audit_event.details,
      ip_address: project_audit_event.ip_address,
      author_name: project_audit_event.author_name,
      entity_path: project_audit_event.entity_path,
      target_details: project_audit_event.target_details,
      target_type: project_audit_event.target_type
    )

    group_event = group_audit_events_table.find_by_id(group_audit_event.id)

    expect(group_event).to have_attributes(
      id: group_audit_event.id,
      created_at: group_audit_event.created_at,
      group_id: group_audit_event.entity_id,
      author_id: group_audit_event.author_id,
      target_id: group_audit_event.target_id,
      details: group_audit_event.details,
      ip_address: group_audit_event.ip_address,
      author_name: group_audit_event.author_name,
      entity_path: group_audit_event.entity_path,
      target_details: group_audit_event.target_details,
      target_type: group_audit_event.target_type
    )

    user_event = user_audit_events_table.find_by_id(user_audit_event.id)

    expect(user_event).to have_attributes(
      id: user_audit_event.id,
      created_at: user_audit_event.created_at,
      user_id: user_audit_event.entity_id,
      author_id: user_audit_event.author_id,
      target_id: user_audit_event.target_id,
      details: user_audit_event.details,
      ip_address: user_audit_event.ip_address,
      author_name: user_audit_event.author_name,
      entity_path: user_audit_event.entity_path,
      target_details: user_audit_event.target_details,
      target_type: user_audit_event.target_type
    )

    instance_event = instance_audit_events_table.find_by_id(instance_audit_event.id)

    expect(instance_event).to have_attributes(
      id: instance_audit_event.id,
      created_at: instance_audit_event.created_at,
      author_id: instance_audit_event.author_id,
      target_id: instance_audit_event.target_id,
      details: instance_audit_event.details,
      ip_address: instance_audit_event.ip_address,
      author_name: instance_audit_event.author_name,
      entity_path: instance_audit_event.entity_path,
      target_details: instance_audit_event.target_details,
      target_type: instance_audit_event.target_type
    )
  end

  context 'when audit events are already present' do
    before do
      project_audit_events_table.create!(
        id: project_audit_event.id,
        created_at: project_audit_event.created_at,
        project_id: project_audit_event.entity_id,
        author_id: project_audit_event.author_id,
        target_id: project_audit_event.target_id,
        details: project_audit_event.details,
        ip_address: project_audit_event.ip_address,
        author_name: project_audit_event.author_name,
        entity_path: project_audit_event.entity_path,
        target_details: project_audit_event.target_details,
        target_type: project_audit_event.target_type
      )

      group_audit_events_table.create!(
        id: group_audit_event.id,
        created_at: group_audit_event.created_at,
        group_id: group_audit_event.entity_id,
        author_id: group_audit_event.author_id,
        target_id: group_audit_event.target_id,
        details: group_audit_event.details,
        ip_address: group_audit_event.ip_address,
        author_name: group_audit_event.author_name,
        entity_path: group_audit_event.entity_path,
        target_details: group_audit_event.target_details,
        target_type: group_audit_event.target_type
      )

      user_audit_events_table.create!(
        id: user_audit_event.id,
        created_at: user_audit_event.created_at,
        user_id: user_audit_event.entity_id,
        author_id: user_audit_event.author_id,
        target_id: user_audit_event.target_id,
        details: user_audit_event.details,
        ip_address: user_audit_event.ip_address,
        author_name: user_audit_event.author_name,
        entity_path: user_audit_event.entity_path,
        target_details: user_audit_event.target_details,
        target_type: user_audit_event.target_type
      )

      instance_audit_events_table.create!(
        id: instance_audit_event.id,
        created_at: instance_audit_event.created_at,
        author_id: instance_audit_event.author_id,
        target_id: instance_audit_event.target_id,
        details: instance_audit_event.details,
        ip_address: instance_audit_event.ip_address,
        author_name: instance_audit_event.author_name,
        entity_path: instance_audit_event.entity_path,
        target_details: instance_audit_event.target_details,
        target_type: instance_audit_event.target_type
      )
    end

    it 'does not duplicate records', :aggregate_failures do
      expect { perform_migration }.not_to change { project_audit_events_table.count }
      expect { perform_migration }.not_to change { group_audit_events_table.count }
      expect { perform_migration }.not_to change { user_audit_events_table.count }
      expect { perform_migration }.not_to change { instance_audit_events_table.count }
    end
  end
end
