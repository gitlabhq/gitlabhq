# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RemoveMetricsUsersStarredDashboards, feature_category: :observability do
  include Database::TableSchemaHelpers

  let(:table_name) { :metrics_users_starred_dashboards }
  let(:column_attributes) do
    [
      { name: 'id', sql_type: 'bigint', null: false, default: nil },
      { name: 'created_at', sql_type: 'timestamp with time zone', null: false, default: nil },
      { name: 'updated_at', sql_type: 'timestamp with time zone', null: false, default: nil },
      { name: 'project_id', sql_type: 'bigint', null: false, default: nil },
      { name: 'user_id', sql_type: 'bigint', null: false, default: nil },
      { name: 'dashboard_path', sql_type: 'text', null: false, default: nil }
    ]
  end

  it 'drops the metrics_dashboard_annotations table' do
    reversible_migration do |migration|
      migration.before -> {
        expect_table_columns_to_match(column_attributes, table_name)
        expect_primary_keys_after_tables([table_name])
        expect_check_constraint(table_name, 'check_79a84a0f57', 'char_length(dashboard_path) <= 255')
        expect_index_to_exist('idx_metrics_users_starred_dashboard_on_user_project_dashboard')
        expect_index_to_exist('index_metrics_users_starred_dashboards_on_project_id')
        expect_foreign_key_to_exist(table_name, 'fk_bd6ae32fac')
        expect_foreign_key_to_exist(table_name, 'fk_d76a2b9a8c')
      }

      migration.after -> {
        expect(connection.table_exists?(table_name)).to be(false)
      }
    end
  end
end
