# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::FixUsernamespaceAuditEvents, feature_category: :audit_events do
  let(:audit_events_table) { partitioned_table(:audit_events) }
  let(:instance_audit_events_table) { partitioned_table(:instance_audit_events) }

  let!(:usernamespace_audit_event) do
    audit_events_table.create!(
      id: 1,
      entity_type: 'Namespaces::UserNamespace',
      entity_id: 1,
      author_id: 1,
      target_id: 1,
      details: 'usernamespace details',
      ip_address: '127.0.0.1',
      author_name: 'usernamespace author',
      entity_path: 'usernamespace/path',
      target_details: 'target details',
      target_type: 'target type',
      created_at: Time.parse("2024-07-04 05:25:54.332355000 +0000")
    )
  end

  let!(:project_audit_event) do
    audit_events_table.create!(
      id: 2,
      entity_type: 'Project',
      entity_id: 2,
      author_id: 2,
      target_id: 2,
      details: 'project details',
      ip_address: '127.0.0.2',
      author_name: 'project author',
      entity_path: 'project/path',
      target_details: 'project target details',
      target_type: 'project target type',
      created_at: Time.parse("2024-07-04 05:25:54.332355000 +0000")
    )
  end

  let(:start_id) { usernamespace_audit_event.id }
  let(:end_id) { project_audit_event.id }

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

  it 'correctly updates and migrates usernamespace audit events', :aggregate_failures do
    expect do
      expect(ActiveRecord::QueryRecorder.new { perform_migration }.count).to eq(6)
    end.to change {
      audit_events_table.where(entity_type: 'Namespaces::UserNamespace').count
    }.from(1).to(0)
     .and change {
       audit_events_table.where(
         entity_type: 'Gitlab::Audit::InstanceScope', entity_id: 1).count
     }.from(0).to(1)
      .and change {
        instance_audit_events_table.count
      }.from(0).to(1)

    updated_audit_event = audit_events_table.find_by_id(usernamespace_audit_event.id)
    expect(updated_audit_event).to have_attributes(
      entity_type: 'Gitlab::Audit::InstanceScope',
      entity_id: 1
    )

    instance_event = instance_audit_events_table.first

    expect(instance_event).to have_attributes(
      id: usernamespace_audit_event.id,
      created_at: usernamespace_audit_event.created_at,
      author_id: usernamespace_audit_event.author_id,
      target_id: usernamespace_audit_event.target_id,
      details: usernamespace_audit_event.details,
      ip_address: usernamespace_audit_event.ip_address,
      author_name: usernamespace_audit_event.author_name,
      entity_path: usernamespace_audit_event.entity_path,
      target_details: usernamespace_audit_event.target_details,
      target_type: usernamespace_audit_event.target_type
    )
  end

  it 'does not affect project audit events' do
    expect { perform_migration }.not_to change { audit_events_table.find_by_id(project_audit_event.id).attributes }
  end

  context 'when instance audit event already exists' do
    before do
      instance_audit_events_table.create!(
        id: usernamespace_audit_event.id,
        created_at: usernamespace_audit_event.created_at,
        author_id: usernamespace_audit_event.author_id,
        target_id: usernamespace_audit_event.target_id,
        details: usernamespace_audit_event.details,
        ip_address: usernamespace_audit_event.ip_address,
        author_name: usernamespace_audit_event.author_name,
        entity_path: usernamespace_audit_event.entity_path,
        target_details: usernamespace_audit_event.target_details,
        target_type: usernamespace_audit_event.target_type
      )
    end

    it 'does not duplicate records' do
      expect { perform_migration }.not_to change { instance_audit_events_table.count }
    end
  end

  describe '#quote_values' do
    let(:events) do
      [
        [1, Time.zone.now, 2, 3, 'details', IPAddr.new('127.0.0.1'), 'author', 'path', 'target details', 'type'],
        [4, Time.zone.now, 5, 6, 'more details', IPAddr.new('192.168.0.1'), 'another author', 'another/path',
          'more target details', 'another type']
      ]
    end

    it 'correctly quotes values' do
      migration = described_class.new(start_id: 1, end_id: 2, batch_table: :audit_events, batch_column: :id,
        sub_batch_size: 2, pause_ms: 0, connection: ActiveRecord::Base.connection)
      quoted_values = migration.send(:quote_values, events)

      expect(quoted_values).to be_a(String)
      expect(quoted_values).to include("'127.0.0.1'")
      expect(quoted_values).to include("'192.168.0.1'")
      expect(quoted_values).to include("'details'")
      expect(quoted_values).to include("'more details'")
      expect(quoted_values).to include("'author'")
      expect(quoted_values).to include("'another author'")
      expect(quoted_values).to include("'path'")
      expect(quoted_values).to include("'another/path'")
      expect(quoted_values).to include("'target details'")
      expect(quoted_values).to include("'more target details'")
      expect(quoted_values).to include("'type'")
      expect(quoted_values).to include("'another type'")
    end
  end
end
