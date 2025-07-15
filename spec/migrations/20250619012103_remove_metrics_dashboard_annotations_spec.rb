# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RemoveMetricsDashboardAnnotations, feature_category: :observability do
  include Database::TableSchemaHelpers

  let(:table_name) { :metrics_dashboard_annotations }
  let(:column_attributes) do
    [
      { name: 'id', sql_type: 'bigint', null: false, default: nil },
      { name: 'starting_at', sql_type: 'timestamp with time zone', null: false, default: nil },
      { name: 'ending_at', sql_type: 'timestamp with time zone', null: true, default: nil },
      { name: 'environment_id', sql_type: 'bigint', null: true, default: nil },
      { name: 'cluster_id', sql_type: 'bigint', null: true, default: nil },
      { name: 'dashboard_path', sql_type: 'character varying(255)', null: false, default: nil },
      { name: 'panel_xid', sql_type: 'character varying(255)', null: true, default: nil },
      { name: 'description', sql_type: 'text', null: false, default: nil }
    ]
  end

  it 'drops the metrics_dashboard_annotations table' do
    reversible_migration do |migration|
      migration.before -> {
        expect_table_columns_to_match(column_attributes, table_name)
        expect_primary_keys_after_tables([table_name])
        expect_index_to_exist('index_metrics_dashboard_annotations_on_cluster_id_and_3_columns')
        expect_index_to_exist('index_metrics_dashboard_annotations_on_environment_id_and_3_col')
        expect_index_to_exist('index_metrics_dashboard_annotations_on_timespan_end')
        expect_foreign_key_to_exist(table_name, 'fk_rails_345ab51043')
        expect_foreign_key_to_exist(table_name, 'fk_rails_aeb11a7643')
      }

      migration.after -> {
        expect(connection.table_exists?(table_name)).to be(false)
      }
    end
  end
end
