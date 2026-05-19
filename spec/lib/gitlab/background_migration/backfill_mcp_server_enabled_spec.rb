# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillMcpServerEnabled,
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
    context 'when namespace has duo_features_enabled=true and experiment_features_enabled=true' do
      let!(:group) { create_group(duo_features_enabled: true, experiment_features_enabled: true) }

      it 'sets mcp_server_enabled to true' do
        migration.perform

        expect(namespace_settings.find_by(namespace_id: group.id).mcp_server_enabled).to be true
      end
    end

    context 'when namespace has duo_features_enabled=false' do
      let!(:group) { create_group(duo_features_enabled: false, experiment_features_enabled: true) }

      it 'sets mcp_server_enabled to false' do
        migration.perform

        expect(namespace_settings.find_by(namespace_id: group.id).mcp_server_enabled).to be false
      end
    end

    context 'when namespace has experiment_features_enabled=false' do
      let!(:group) { create_group(duo_features_enabled: true, experiment_features_enabled: false) }

      it 'sets mcp_server_enabled to false' do
        migration.perform

        expect(namespace_settings.find_by(namespace_id: group.id).mcp_server_enabled).to be false
      end
    end

    # duo_features_enabled is nullable; experiment_features_enabled is NOT NULL so nil is not tested
    context 'when duo_features_enabled is nil' do
      let!(:group) { create_group(duo_features_enabled: nil, experiment_features_enabled: true) }

      it 'sets mcp_server_enabled to false' do
        migration.perform

        expect(namespace_settings.find_by(namespace_id: group.id).mcp_server_enabled).to be false
      end
    end

    context 'when mcp_server_enabled is already set to the opposite value' do
      let!(:group) { create_group(duo_features_enabled: true, experiment_features_enabled: true) }

      before do
        namespace_settings.find_by(namespace_id: group.id).update!(mcp_server_enabled: false)
      end

      it 'overwrites the existing value' do
        migration.perform

        expect(namespace_settings.find_by(namespace_id: group.id).mcp_server_enabled).to be true
      end
    end

    context 'when the batch contains no top-level groups' do
      before do
        namespaces.create!(name: 'user1', path: 'user1', type: 'User', organization_id: organization.id)
      end

      it 'does not update any namespace_settings rows' do
        expect { migration.perform }.not_to change {
          namespace_settings.where.not(mcp_server_enabled: nil).count
        }
      end
    end

    context 'when namespace is a sub-group' do
      let(:parent_group) do
        namespaces.create!(name: 'parent-group', path: 'parent-group', type: 'Group', parent_id: nil,
          organization_id: organization.id)
      end

      let(:sub_group) do
        namespaces.create!(name: 'sub-group', path: 'sub-group', type: 'Group', parent_id: parent_group.id,
          organization_id: organization.id)
      end

      before do
        namespace_settings.create!(namespace_id: sub_group.id, duo_features_enabled: true,
          experiment_features_enabled: true)
      end

      it 'does not update namespace_settings' do
        migration.perform

        expect(namespace_settings.find_by(namespace_id: sub_group.id).mcp_server_enabled).to be_nil
      end
    end

    context 'when batch contains top-level groups and sub-groups' do
      let!(:top_level_group) { create_group(duo_features_enabled: true, experiment_features_enabled: true) }
      let(:parent_group) do
        namespaces.create!(name: 'parent-group', path: 'parent-group', type: 'Group', parent_id: nil,
          organization_id: organization.id)
      end

      let(:sub_group) do
        namespaces.create!(name: 'sub-group', path: 'sub-group', type: 'Group', parent_id: parent_group.id,
          organization_id: organization.id)
      end

      before do
        namespace_settings.create!(namespace_id: sub_group.id, duo_features_enabled: true,
          experiment_features_enabled: true)
      end

      it 'only updates top-level group namespace_settings' do
        migration.perform

        expect(namespace_settings.find_by(namespace_id: top_level_group.id).mcp_server_enabled).to be true
        expect(namespace_settings.find_by(namespace_id: sub_group.id).mcp_server_enabled).to be_nil
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

  def create_group(duo_features_enabled: true, experiment_features_enabled: true)
    path = "test-group-#{SecureRandom.hex(4)}"
    namespace = namespaces.create!(name: path, path: path, type: 'Group', parent_id: nil,
      organization_id: organization.id)
    namespace_settings.create!(
      namespace_id: namespace.id,
      duo_features_enabled: duo_features_enabled,
      experiment_features_enabled: experiment_features_enabled
    )
    namespace
  end
end
