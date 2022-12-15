# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe CleanupBigintConversionForCiBuilds, feature_category: :continuous_integration do
  let(:ci_builds) { table(:ci_builds) }

  it 'correctly migrates up and down' do
    reversible_migration do |migration|
      migration.before -> {
        expect(ci_builds.column_names).to include('id_convert_to_bigint')
        expect(ci_builds.column_names).to include('stage_id_convert_to_bigint')
      }

      migration.after -> {
        ci_builds.reset_column_information
        expect(ci_builds.column_names).not_to include('id_convert_to_bigint')
        expect(ci_builds.column_names).not_to include('stage_id_convert_to_bigint')
      }
    end
  end
end
