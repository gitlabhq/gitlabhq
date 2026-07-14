# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RemoveWorkItemDescriptionsNamespaceIdFk, feature_category: :team_planning do
  include Database::TableSchemaHelpers

  let(:table_name) { :work_item_descriptions }

  it 'removes the namespace_id foreign key constraint' do
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
