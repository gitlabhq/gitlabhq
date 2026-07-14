# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::ResyncMcpServerEnabled,
  feature_category: :mcp_server do
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:namespace_settings) { table(:namespace_settings) }

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
    context 'when mcp_server_enabled is stale (false but should be true)' do
      let!(:group) do
        create_group(duo_features_enabled: true, experiment_features_enabled: true, mcp_server_enabled: false)
      end

      it 'sets mcp_server_enabled to true' do
        migration.perform

        expect(namespace_settings.find_by(namespace_id: group.id).mcp_server_enabled).to be true
      end
    end

    context 'when mcp_server_enabled is stale (true but duo_features_enabled is false)' do
      let!(:group) do
        create_group(duo_features_enabled: false, experiment_features_enabled: true, mcp_server_enabled: true)
      end

      it 'sets mcp_server_enabled to false' do
        migration.perform

        expect(namespace_settings.find_by(namespace_id: group.id).mcp_server_enabled).to be false
      end
    end

    context 'when mcp_server_enabled is stale (true but experiment_features_enabled is false)' do
      let!(:group) do
        create_group(duo_features_enabled: true, experiment_features_enabled: false, mcp_server_enabled: true)
      end

      it 'sets mcp_server_enabled to false' do
        migration.perform

        expect(namespace_settings.find_by(namespace_id: group.id).mcp_server_enabled).to be false
      end
    end

    # duo_features_enabled is nullable; experiment_features_enabled is NOT NULL so nil is not tested
    context 'when mcp_server_enabled is stale (true but duo_features_enabled is nil)' do
      let!(:group) do
        create_group(duo_features_enabled: nil, experiment_features_enabled: true, mcp_server_enabled: true)
      end

      it 'sets mcp_server_enabled to false' do
        migration.perform

        expect(namespace_settings.find_by(namespace_id: group.id).mcp_server_enabled).to be false
      end
    end

    context 'when mcp_server_enabled is already correct' do
      let!(:group) do
        create_group(duo_features_enabled: true, experiment_features_enabled: true, mcp_server_enabled: true)
      end

      it 'does not update the row' do
        expect { migration.perform }.not_to(
          change { namespace_settings.find_by(namespace_id: group.id).updated_at }
        )
      end
    end

    context 'when namespace is not a Group' do
      before do
        user_namespace = namespaces.create!(name: 'user1', path: 'user1', type: 'User',
          organization_id: organization.id)
        namespace_settings.create!(namespace_id: user_namespace.id, duo_features_enabled: true,
          experiment_features_enabled: true, mcp_server_enabled: false)
      end

      it 'does not update namespace_settings' do
        expect { migration.perform }.not_to(
          change { namespace_settings.where(mcp_server_enabled: false).count }
        )
      end
    end

    context 'when namespace is a sub-group' do
      let(:parent_group) do
        namespaces.create!(name: 'parent-group', path: 'parent-group', type: 'Group', parent_id: nil,
          organization_id: organization.id)
      end

      before do
        sub_group = namespaces.create!(name: 'sub-group', path: 'sub-group', type: 'Group',
          parent_id: parent_group.id, organization_id: organization.id)
        namespace_settings.create!(namespace_id: sub_group.id, duo_features_enabled: true,
          experiment_features_enabled: true, mcp_server_enabled: false)
      end

      it 'does not update namespace_settings' do
        migration.perform

        expect(namespace_settings.where(mcp_server_enabled: false).count).to eq(1)
      end
    end

    context 'when top-level group has no namespace_settings row' do
      before do
        namespaces.create!(name: 'bare-group', path: 'bare-group', type: 'Group', parent_id: nil,
          organization_id: organization.id)
      end

      it 'does not raise and creates no namespace_settings rows' do
        expect { migration.perform }.not_to raise_error
        expect(namespace_settings.count).to eq(0)
      end
    end
  end

  def create_group(duo_features_enabled:, experiment_features_enabled:, mcp_server_enabled:)
    path = "test-group-#{SecureRandom.hex(4)}"
    namespace = namespaces.create!(name: path, path: path, type: 'Group', parent_id: nil,
      organization_id: organization.id)
    namespace_settings.create!(
      namespace_id: namespace.id,
      duo_features_enabled: duo_features_enabled,
      experiment_features_enabled: experiment_features_enabled,
      mcp_server_enabled: mcp_server_enabled
    )
    namespace
  end
end
