# frozen_string_literal: true

require 'spec_helper'
require_migration!

# rubocop: disable Migration/Datetime -- wrong offense detection for the timestamp attribute
RSpec.describe MigrateAiTroubleshootJobEventsToAiUsageEvents, migration: :gitlab_main, feature_category: :value_stream_management, migration_version: 20250721095854 do
  let(:migration) { described_class.new }
  let(:users) { table(:users) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:organizations) { table(:organizations) }
  let(:troubleshoot_events) { partitioned_table(:ai_troubleshoot_job_events, by: :timestamp) }
  let(:usage_events) { partitioned_table(:ai_usage_events, by: :timestamp) }

  context 'with Gitlab.ee', if: Gitlab.ee? do
    describe '#up' do
      let(:organization) { organizations.create!(name: 'org', path: 'org') }
      let(:namespace1) { namespaces.create!(name: 'foo', path: 'foo', organization_id: organization.id) }
      let(:namespace2) do
        namespaces.create!(name: 'bar', path: 'bar', organization_id: organization.id, parent_id: namespace1.id)
      end

      let(:project_namespace1) { namespaces.create!(name: 'foo', path: 'foo', organization_id: organization.id) }
      let(:project_namespace2) { namespaces.create!(name: 'foo', path: 'foo', organization_id: organization.id) }

      let(:project1) do
        projects.create!(name: 'p1', path: 'p1', organization_id: organization.id, namespace_id: namespace1.id,
          project_namespace_id: project_namespace1.id)
      end

      let(:project2) do
        projects.create!(name: 'p2', path: 'p2', organization_id: organization.id, namespace_id: namespace2.id,
          project_namespace_id: project_namespace2.id)
      end

      let(:event_in_group) do
        troubleshoot_events.create!(
          timestamp: Time.current,
          user_id: 1,
          job_id: 5,
          namespace_path: "#{namespace1.id}/",
          project_id: project1.id,
          event: 1,
          payload: {},
          created_at: Time.current,
          updated_at: Time.current
        )
      end

      let(:event_in_subgroup) do
        troubleshoot_events.create!(
          timestamp: Time.current,
          user_id: 2,
          job_id: 6,
          namespace_path: "#{namespace1.id}/#{namespace2.id}/",
          project_id: project2.id,
          event: 1,
          payload: { 'test' => 1 },
          created_at: Time.current,
          updated_at: Time.current
        )
      end

      let(:event_with_missing_namespace_path) do
        troubleshoot_events.create!(
          timestamp: Time.current,
          user_id: 4,
          job_id: 7,
          namespace_path: nil,
          project_id: project1.id,
          event: 1,
          payload: {},
          created_at: Time.current,
          updated_at: Time.current
        )
      end

      before do
        namespace1.update!(traversal_ids: [namespace1.id])
        namespace2.update!(traversal_ids: [namespace1.id, namespace2.id])

        project1
        project2
      end

      it 'migrates data from ai_troubleshoot_job_events table to ai_usage_events' do
        event_in_group.reload
        event_in_subgroup.reload
        event_with_missing_namespace_path.reload

        migrate!

        expect(usage_events.count).to eq(3)

        migrated_event1 = usage_events.find_by(user_id: event_in_subgroup.user_id)
        expect(migrated_event1).to be_present

        expect(migrated_event1).to have_attributes(
          timestamp: event_in_subgroup.timestamp,
          event: described_class::NEW_EVENT_TYPE,
          extras: { "job_id" => 6, "project_id" => event_in_subgroup.project_id, "test" => 1 },
          namespace_id: namespace2.id,
          created_at: event_in_subgroup.created_at,
          organization_id: namespace2.organization_id
        )

        migrated_event2 = usage_events.find_by(user_id: event_in_group.user_id)
        expect(migrated_event2).to be_present

        expect(migrated_event2).to have_attributes(
          timestamp: event_in_group.timestamp,
          event: described_class::NEW_EVENT_TYPE,
          extras: { "job_id" => 5, "project_id" => event_in_group.project_id },
          namespace_id: namespace1.id,
          created_at: event_in_group.created_at,
          organization_id: namespace1.organization_id
        )

        migrated_event4 = usage_events.find_by(user_id: event_with_missing_namespace_path.user_id)
        expect(migrated_event4).to be_present

        expect(migrated_event4).to have_attributes(
          timestamp: event_with_missing_namespace_path.timestamp,
          event: described_class::NEW_EVENT_TYPE,
          extras: { "job_id" => 7, "project_id" => event_with_missing_namespace_path.project_id },
          namespace_id: nil,
          created_at: event_with_missing_namespace_path.created_at,
          organization_id: project1.organization_id
        )
      end

      it 'does not insert data twice' do
        event_in_group.reload
        event_in_subgroup.reload
        event_with_missing_namespace_path.reload

        migration.up
        migration.up

        expect(usage_events.count).to eq(3)
      end
    end

    describe '#down' do
      it 'does nothing' do
        migration.up
        expect { migration.down }.not_to change { usage_events.count }
      end
    end
  end

  context 'with Gitlab.foss', unless: Gitlab.ee? do
    it 'does not fail' do
      expect { migration.up }.not_to raise_error
    end

    describe '#down' do
      it 'does not fail' do
        migration.up

        expect { migration.down }.not_to raise_error
      end
    end
  end
end
# rubocop: enable Migration/Datetime
