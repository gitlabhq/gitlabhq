# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe DropInt4ColumnForCiSourcesPipelines, feature_category: :pipeline_authoring do
  let(:ci_sources_pipelines) { table(:ci_sources_pipelines) }

  it 'correctly migrates up and down' do
    reversible_migration do |migration|
      migration.before -> {
        expect(ci_sources_pipelines.column_names).to include('source_job_id_convert_to_bigint')
      }

      migration.after -> {
        ci_sources_pipelines.reset_column_information
        expect(ci_sources_pipelines.column_names).not_to include('source_job_id_convert_to_bigint')
      }
    end
  end
end
