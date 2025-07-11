# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::UpdateRequireDpopForManageApiEndpointsToFalse, :aggregate_failures, feature_category: :system_access do
  let!(:organizations_table) { table(:organizations) }
  let!(:users_table) { table(:users) }
  let!(:namespaces_table) { table(:namespaces) }
  let!(:namespace_settings_table) { table(:namespace_settings) }

  let!(:organization) { organizations_table.create!(name: 'org1', path: 'org1') }
  let!(:dpop_user1) do
    users_table.create!(email: 'john_doe@gitlab.com', projects_limit: 1, organization_id: organization.id)
  end

  let!(:dpop_user2) do
    users_table.create!(email: 'wally_west@amazon.ca', projects_limit: 1, organization_id: organization.id)
  end

  let!(:dpop_user1_namespace) do
    namespaces_table.create!(name: 'JD', path: 'JD', organization_id: organization.id, owner_id: dpop_user1.id)
  end

  let!(:dpop_user2_namespace) do
    namespaces_table.create!(name: 'WW', path: 'WW', organization_id: organization.id, owner_id: dpop_user2.id)
  end

  let!(:dpop_user1_namespace_setting) do
    namespace_settings_table.create!(namespace_id: dpop_user1_namespace.id, require_dpop_for_manage_api_endpoints: true)
  end

  let!(:dpop_user2_namespace_setting) { namespace_settings_table.create!(namespace_id: dpop_user2_namespace.id) }

  let!(:table_name) { :namespace_settings }
  let!(:batch_column) { :namespace_id }
  let!(:sub_batch_size) { 1 }
  let!(:pause_ms) { 0 }

  let!(:migration) do
    described_class.new(
      start_id: namespace_settings_table.first.id,
      end_id: namespace_settings_table.last.id,
      batch_table: table_name,
      batch_column: batch_column,
      sub_batch_size: sub_batch_size,
      pause_ms: pause_ms,
      connection: ApplicationRecord.connection
    )
  end

  subject(:perform_batched_background_migration) do
    migration.perform
  end

  describe '#perform' do
    it 'updates the :require_dpop_for_manage_api_endpoints column to false in batches' do
      perform_batched_background_migration

      expect(dpop_user1_namespace_setting.reload.require_dpop_for_manage_api_endpoints).to be(false)
      expect(dpop_user2_namespace_setting.reload.require_dpop_for_manage_api_endpoints).to be(false)
    end
  end
end
