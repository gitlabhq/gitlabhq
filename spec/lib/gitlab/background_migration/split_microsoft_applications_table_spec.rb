# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::SplitMicrosoftApplicationsTable, feature_category: :system_access do
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:system_access_microsoft_applications) { table(:system_access_microsoft_applications) }
  let(:system_access_group_microsoft_applications) { table(:system_access_group_microsoft_applications) }

  let(:organization) { organizations.create!(name: 'organization', path: 'organization') }
  let(:group) do
    namespaces.create!(name: 'test-group', path: 'test-group', type: 'Group', organization_id: organization.id)
  end

  let(:migration_attrs) do
    {
      start_id: system_access_microsoft_applications.minimum(:id),
      end_id: system_access_microsoft_applications.maximum(:id),
      batch_table: :system_access_microsoft_applications,
      batch_column: :id,
      sub_batch_size: 2,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    }
  end

  let(:base_app_attributes) do
    {
      enabled: true,
      tenant_xid: 'abc123',
      client_xid: 'def456',
      login_endpoint: 'http://microsoft-login.test',
      graph_endpoint: 'http://microsoft-graph.test',
      encrypted_client_secret: 'fake-data-not-real',
      encrypted_client_secret_iv: 'fake-data-not-real-2'
    }
  end

  let!(:group_app) do
    system_access_microsoft_applications.create!(
      base_app_attributes.merge(namespace_id: group.id)
    )
  end

  let!(:instance_app) do
    system_access_microsoft_applications.create!(base_app_attributes)
  end

  let(:instance) { described_class.new(**migration_attrs) }

  describe '#perform' do
    subject(:perform) { instance.perform }

    it 'transfers all attributes of microsoft applications' do
      perform

      expect(system_access_group_microsoft_applications.count).to eq(1)

      record = system_access_group_microsoft_applications.first

      %w[enabled tenant_xid client_xid login_endpoint graph_endpoint
        encrypted_client_secret encrypted_client_secret_iv].each do |field|
        expect(record[field]).to eq(group_app[field])
      end

      expect(record.group_id).to eq(group_app.namespace_id)
      expect(record.temp_source_id).to eq(group_app.id)
      expect(record.created_at).to be_within(1.second).of(group_app.created_at)
      expect(record.updated_at).to be_within(1.second).of(group_app.updated_at)
    end

    it 'does not migrate apps without namespace_id' do
      perform

      relation = system_access_group_microsoft_applications.where(temp_source_id: instance_app.id)
      expect(relation.count).to eq(0)
    end

    it 'handles conflicts on group_id gracefully' do
      system_access_group_microsoft_applications.create!(
        base_app_attributes.merge(
          group_id: group.id,
          tenant_xid: 'zxc123'
        )
      )

      expect { perform }.not_to raise_error

      expect(system_access_group_microsoft_applications.count).to eq(1)

      record = system_access_group_microsoft_applications.first
      expect(record.tenant_xid).to eq('zxc123')
    end
  end
end
