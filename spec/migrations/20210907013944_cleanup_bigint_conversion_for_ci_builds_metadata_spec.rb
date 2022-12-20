# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe CleanupBigintConversionForCiBuildsMetadata, feature_category: :continuous_integration do
  let(:ci_builds_metadata) { table(:ci_builds_metadata) }

  it 'correctly migrates up and down' do
    reversible_migration do |migration|
      migration.before -> {
        expect(ci_builds_metadata.column_names).to include('id_convert_to_bigint')
        expect(ci_builds_metadata.column_names).to include('build_id_convert_to_bigint')
      }

      migration.after -> {
        ci_builds_metadata.reset_column_information
        expect(ci_builds_metadata.column_names).not_to include('id_convert_to_bigint')
        expect(ci_builds_metadata.column_names).not_to include('build_id_convert_to_bigint')
      }
    end
  end
end
