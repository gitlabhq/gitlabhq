# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RemoveClustersIntegrationPrometheus, feature_category: :integrations do
  include Database::TableSchemaHelpers

  let(:table_name) { :clusters_integration_prometheus }
  let(:column_attributes) do
    [
      { name: 'created_at', sql_type: 'timestamp with time zone', null: false, default: nil },
      { name: 'updated_at', sql_type: 'timestamp with time zone', null: false, default: nil },
      { name: 'cluster_id', sql_type: 'bigint', null: false, default: nil },
      { name: 'enabled', sql_type: 'boolean', null: false, default: 'false' },
      { name: 'encrypted_alert_manager_token', sql_type: 'text', null: true, default: nil },
      { name: 'encrypted_alert_manager_token_iv', sql_type: 'text', null: true, default: nil },
      { name: 'health_status', sql_type: 'smallint', null: false, default: '0' }
    ]
  end

  it 'drops the clusters_integration_prometheus table' do
    reversible_migration do |migration|
      migration.before -> {
        expect_table_columns_to_match(column_attributes, table_name)
        expect_primary_keys_after_tables([table_name])
        expect_index_to_exist('index_clusters_integration_prometheus_enabled')
      }

      migration.after -> {
        expect(connection.table_exists?(table_name)).to be(false)
      }
    end
  end
end
