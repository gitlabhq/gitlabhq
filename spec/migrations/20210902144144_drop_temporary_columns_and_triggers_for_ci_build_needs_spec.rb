# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe DropTemporaryColumnsAndTriggersForCiBuildNeeds, feature_category: :pipeline_authoring do
  let(:ci_build_needs_table) { table(:ci_build_needs) }

  it 'correctly migrates up and down' do
    reversible_migration do |migration|
      migration.before -> {
        expect(ci_build_needs_table.column_names).to include('build_id_convert_to_bigint')
      }

      migration.after -> {
        ci_build_needs_table.reset_column_information
        expect(ci_build_needs_table.column_names).not_to include('build_id_convert_to_bigint')
      }
    end
  end
end
