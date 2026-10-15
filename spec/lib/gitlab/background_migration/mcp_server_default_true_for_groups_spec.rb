# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::McpServerDefaultTrueForGroups, feature_category: :mcp_server do
  using RSpec::Parameterized::TableSyntax

  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:namespace_settings) { table(:namespace_settings) }
  let(:group_audit_events) { table(:group_audit_events) }

  let!(:organization) { organizations.create!(name: 'Default', path: 'default') }

  subject(:migration) do
    described_class.new(
      start_id: namespaces.minimum(:id),
      end_id: namespaces.maximum(:id),
      batch_table: :namespaces,
      batch_column: :id,
      sub_batch_size: 100,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    )
  end

  describe '#perform' do
    where(:duo_features_enabled, :lock_duo_features_enabled, :experiment_features_enabled, :mcp_server_enabled,
      :expected) do
      # Duo availability does not affect MCP: Always on / On by default / Off by default /
      # Always off / never set
      true  | true  | true  | false | true
      true  | false | true  | false | true
      false | false | true  | false | true
      false | true  | true  | false | true
      nil   | false | true  | false | true
      # Beta and experimental features off no longer keeps MCP off
      true  | false | false | false | true
      # Created without a value, which read as off
      true  | false | true  | nil   | true
    end

    with_them do
      let!(:group) do
        create_group(duo_features_enabled: duo_features_enabled, lock_duo_features_enabled: lock_duo_features_enabled,
          experiment_features_enabled: experiment_features_enabled, mcp_server_enabled: mcp_server_enabled)
      end

      it 'sets mcp_server_enabled' do
        migration.perform

        expect(setting_for(group).mcp_server_enabled).to be(expected)
      end
    end

    context 'when mcp_server_enabled is already on' do
      let!(:group) { create_group(mcp_server_enabled: true) }

      # update_all doesn't set updated_at, but every UPDATE writes a new tuple and so changes ctid.
      it 'does not rewrite the row' do
        ctid = -> { namespace_settings.where(namespace_id: group.id).pick(Arel.sql('ctid::text')) }

        expect { migration.perform }.not_to change { ctid.call }
      end
    end

    context 'with MCP audit events' do
      let!(:group) { create_group(mcp_server_enabled: false) }

      it 'leaves the row alone when an Owner turned MCP off' do
        create_mcp_audit_event(group, from: true, to: false)

        migration.perform

        expect(setting_for(group).mcp_server_enabled).to be false
      end

      it 'turns MCP on when the only audit event turned it on' do
        create_mcp_audit_event(group, from: false, to: true)

        migration.perform

        expect(setting_for(group).mcp_server_enabled).to be true
      end

      it 'turns MCP on when an Owner turned it off and later back on' do
        create_mcp_audit_event(group, from: true, to: false, created_at: 2.days.ago)
        create_mcp_audit_event(group, from: false, to: true, created_at: 1.day.ago)

        migration.perform

        expect(setting_for(group).mcp_server_enabled).to be true
      end

      it 'leaves the row alone when an Owner turned it on and later off' do
        create_mcp_audit_event(group, from: false, to: true, created_at: 2.days.ago)
        create_mcp_audit_event(group, from: true, to: false, created_at: 1.day.ago)

        migration.perform

        expect(setting_for(group).mcp_server_enabled).to be false
      end

      it 'ignores events recorded against another group' do
        create_mcp_audit_event(create_group(mcp_server_enabled: true), from: true, to: false)

        migration.perform

        expect(setting_for(group).mcp_server_enabled).to be true
      end

      it 'ignores events recorded before group MCP changes were audited' do
        create_mcp_audit_event(group, from: true, to: false, created_at: Time.utc(2026, 6, 17))

        migration.perform

        expect(setting_for(group).mcp_server_enabled).to be true
      end

      it 'ignores other audit events on the group' do
        create_mcp_audit_event(group, from: true, to: false, event_name: 'duo_features_enabled_updated')

        migration.perform

        expect(setting_for(group).mcp_server_enabled).to be true
      end
    end

    context 'when the namespace is a sub-group' do
      let!(:parent) { create_group(mcp_server_enabled: true) }

      where(:mcp_server_enabled) { [nil, false] }

      with_them do
        let!(:group) { create_group(parent_id: parent.id, mcp_server_enabled: mcp_server_enabled) }

        it 'leaves the row alone, because only root groups are consulted at request time' do
          migration.perform

          expect(setting_for(group).mcp_server_enabled).to be(mcp_server_enabled)
        end
      end
    end

    context 'when the namespace is not a group' do
      where(:mcp_server_enabled) { [nil, false] }

      with_them do
        let!(:namespace) { create_group(type: 'User', mcp_server_enabled: mcp_server_enabled) }

        it 'leaves the row alone' do
          migration.perform

          expect(setting_for(namespace).mcp_server_enabled).to be(mcp_server_enabled)
        end
      end
    end

    context 'when a root group has no namespace_settings row' do
      before do
        namespaces.create!(name: 'bare', path: 'bare', type: 'Group', parent_id: nil,
          organization_id: organization.id)
      end

      it 'does not raise and creates no rows' do
        expect { migration.perform }.not_to raise_error
        expect(namespace_settings.count).to eq(0)
      end
    end
  end

  def setting_for(namespace)
    namespace_settings.find_by(namespace_id: namespace.id)
  end

  def create_mcp_audit_event(
    namespace, from:, to:, created_at: Time.current, event_name: 'mcp_server_enabled_updated')
    group_audit_events.create!(
      group_id: namespace.id,
      author_id: 1,
      created_at: created_at,
      event_name: event_name,
      details: { change: :mcp_server_enabled, from: from, to: to }.to_yaml
    )
  end

  def create_group(
    mcp_server_enabled:, duo_features_enabled: true, lock_duo_features_enabled: false,
    experiment_features_enabled: true, parent_id: nil, type: 'Group')
    path = "group-#{SecureRandom.hex(4)}"
    namespace = namespaces.create!(name: path, path: path, type: type, parent_id: parent_id,
      organization_id: organization.id)

    namespace_settings.create!(
      namespace_id: namespace.id,
      duo_features_enabled: duo_features_enabled,
      lock_duo_features_enabled: lock_duo_features_enabled,
      experiment_features_enabled: experiment_features_enabled,
      mcp_server_enabled: mcp_server_enabled
    )

    namespace
  end
end
