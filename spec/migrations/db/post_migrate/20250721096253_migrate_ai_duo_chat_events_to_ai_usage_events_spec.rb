# frozen_string_literal: true

require 'spec_helper'
require_migration!

# rubocop: disable Migration/Datetime -- wrong offense detection for the timestamp attribute
RSpec.describe MigrateAiDuoChatEventsToAiUsageEvents, migration: :gitlab_main, feature_category: :value_stream_management, migration_version: 20250721095854 do
  let(:migration) { described_class.new }
  let(:users) { table(:users) }
  let(:namespaces) { table(:namespaces) }
  let(:organizations) { table(:organizations) }
  let(:chat_events) { partitioned_table(:ai_duo_chat_events, by: :timestamp) }
  let(:usage_events) { partitioned_table(:ai_usage_events, by: :timestamp) }

  context 'with Gitlab.ee', if: Gitlab.ee? do
    describe '#up' do
      let(:organization) { organizations.create!(name: 'org', path: 'org') }
      let(:namespace1) { namespaces.create!(name: 'foo', path: 'foo', organization_id: organization.id) }
      let(:namespace2) do
        namespaces.create!(name: 'bar', path: 'bar', organization_id: organization.id, parent_id: namespace1.id)
      end

      let(:event_in_group) do
        chat_events.create!(
          timestamp: Time.current,
          user_id: 1,
          namespace_path: "#{namespace1.id}/",
          organization_id: organization.id,
          event: 1,
          payload: {},
          created_at: Time.current,
          updated_at: Time.current
        )
      end

      let(:event_in_subgroup) do
        chat_events.create!(
          timestamp: Time.current,
          user_id: 2,
          namespace_path: "#{namespace1.id}/#{namespace2.id}/",
          organization_id: organization.id,
          event: 1,
          payload: { 'test' => 1 },
          created_at: Time.current,
          updated_at: Time.current
        )
      end

      let(:event_with_unknown_namespace_path) do
        chat_events.create!(
          timestamp: Time.current,
          user_id: 3,
          namespace_path: "#{non_existing_record_id}/",
          organization_id: organization.id,
          event: 1,
          payload: {},
          created_at: Time.current,
          updated_at: Time.current
        )
      end

      let(:event_with_missing_namespace_path) do
        chat_events.create!(
          timestamp: Time.current,
          user_id: 4,
          namespace_path: nil,
          organization_id: organization.id,
          event: 1,
          payload: {},
          created_at: Time.current,
          updated_at: Time.current
        )
      end

      before do
        namespace1.update!(traversal_ids: [namespace1.id])
        namespace2.update!(traversal_ids: [namespace1.id, namespace2.id])
      end

      it 'migrates data from ai_duo_chat_events table to ai_usage_events' do
        event_in_group.reload
        event_in_subgroup.reload
        event_with_unknown_namespace_path.reload
        event_with_missing_namespace_path.reload

        migration.up

        expect(usage_events.count).to eq(4)

        migrated_event1 = usage_events.find_by(user_id: event_in_subgroup.user_id)
        expect(migrated_event1).to be_present

        expect(migrated_event1).to have_attributes(
          timestamp: event_in_subgroup.timestamp,
          event: described_class::NEW_EVENT_TYPE,
          extras: event_in_subgroup.payload,
          namespace_id: namespace2.id,
          created_at: event_in_subgroup.created_at,
          organization_id: namespace2.organization_id
        )

        migrated_event2 = usage_events.find_by(user_id: event_in_group.user_id)
        expect(migrated_event2).to be_present

        expect(migrated_event2).to have_attributes(
          timestamp: event_in_group.timestamp,
          event: described_class::NEW_EVENT_TYPE,
          extras: event_in_group.payload,
          namespace_id: namespace1.id,
          created_at: event_in_group.created_at,
          organization_id: namespace1.organization_id
        )

        migrated_event3 = usage_events.find_by(user_id: event_with_unknown_namespace_path.user_id)
        expect(migrated_event3).to be_present

        expect(migrated_event3).to have_attributes(
          timestamp: event_with_unknown_namespace_path.timestamp,
          event: described_class::NEW_EVENT_TYPE,
          extras: event_with_unknown_namespace_path.payload,
          namespace_id: nil,
          created_at: event_with_unknown_namespace_path.created_at,
          organization_id: event_with_unknown_namespace_path.organization_id
        )

        migrated_event4 = usage_events.find_by(user_id: event_with_missing_namespace_path.user_id)
        expect(migrated_event4).to be_present

        expect(migrated_event4).to have_attributes(
          timestamp: event_with_missing_namespace_path.timestamp,
          event: described_class::NEW_EVENT_TYPE,
          extras: event_with_missing_namespace_path.payload,
          namespace_id: nil,
          created_at: event_with_missing_namespace_path.created_at,
          organization_id: event_with_missing_namespace_path.organization_id
        )
      end

      it 'does not insert data twice' do
        event_in_group.reload
        event_in_subgroup.reload
        event_with_unknown_namespace_path.reload
        event_with_missing_namespace_path.reload

        migration.up
        migration.up

        expect(usage_events.count).to eq(4)
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
