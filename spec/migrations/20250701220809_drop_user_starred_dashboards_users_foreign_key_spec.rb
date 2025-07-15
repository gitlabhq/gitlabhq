# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe DropUserStarredDashboardsUsersForeignKey, feature_category: :observability do
  include Database::TableSchemaHelpers
  include MigrationHelpers::MetricsStarredDashboardHelpers

  let(:table_name) { :metrics_users_starred_dashboards }

  it 'does nothing when the table is already dropped' do
    ensure_table_does_not_exist!

    expect { migrate! }.not_to raise_error
    expect { schema_migrate_down! }.not_to raise_error
  end

  it 'drops the users foreign key constraint' do
    ensure_table_exists!

    reversible_migration do |migration|
      migration.before -> {
        expect_foreign_key_to_exist(table_name, described_class::CONSTRAINT_NAME)
      }

      migration.after -> {
        expect_foreign_key_not_to_exist(table_name, described_class::CONSTRAINT_NAME)
      }
    end
  end
end
