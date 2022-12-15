# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe DropInt4ColumnsForCiJobArtifacts, feature_category: :build_artifacts do
  let(:ci_job_artifacts) { table(:ci_job_artifacts) }

  it 'correctly migrates up and down' do
    reversible_migration do |migration|
      migration.before -> {
        expect(ci_job_artifacts.column_names).to include('id_convert_to_bigint')
        expect(ci_job_artifacts.column_names).to include('job_id_convert_to_bigint')
      }

      migration.after -> {
        ci_job_artifacts.reset_column_information
        expect(ci_job_artifacts.column_names).not_to include('id_convert_to_bigint')
        expect(ci_job_artifacts.column_names).not_to include('job_id_convert_to_bigint')
      }
    end
  end
end
