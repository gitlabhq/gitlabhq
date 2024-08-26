# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe CleanupBigintConversionForPackagesBuildInfosPipelineId, feature_category: :continuous_integration do
  let(:packages_build_infos) { table(:packages_build_infos) }

  it 'correctly migrates up and down' do
    reversible_migration do |migration|
      migration.before -> {
        expect(packages_build_infos.column_names).to include('pipeline_id_convert_to_bigint')
      }

      migration.after -> {
        packages_build_infos.reset_column_information
        expect(packages_build_infos.column_names).not_to include('pipeline_id_convert_to_bigint')
      }
    end
  end
end
