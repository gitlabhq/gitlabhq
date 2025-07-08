# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe DropUserStarredDashboardsAgain, feature_category: :observability do
  include Database::TableSchemaHelpers
  include MigrationHelpers::MetricsStarredDashboardHelpers

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

  it 'does nothing when the table is already dropped' do
    ensure_table_does_not_exist!

    expect { migrate! }.not_to raise_error
    expect { schema_migrate_down! }.not_to raise_error
  end

  it 'drops the metrics_users_starred_dashboards table' do
    ensure_table_exists!

    reversible_migration do |migration|
      migration.before -> {
        expect_table_columns_to_match(column_attributes, table_name)
        expect_primary_keys_after_tables([table_name])
        expect_check_constraint(table_name, 'check_79a84a0f57', 'char_length(dashboard_path) <= 255')
        expect_index_to_exist('idx_metrics_users_starred_dashboard_on_user_project_dashboard')
        expect_index_to_exist('index_metrics_users_starred_dashboards_on_project_id')
      }

      migration.after -> {
        expect(connection.table_exists?(table_name)).to be(false)
      }
    end
  end
end
