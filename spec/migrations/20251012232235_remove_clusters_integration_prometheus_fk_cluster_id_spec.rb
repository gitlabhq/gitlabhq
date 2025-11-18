# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RemoveClustersIntegrationPrometheusFkClusterId, feature_category: :integrations do
  include Database::TableSchemaHelpers

  let(:table_name) { :clusters_integration_prometheus }

  it 'drops the projects foreign key constraint' do
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
