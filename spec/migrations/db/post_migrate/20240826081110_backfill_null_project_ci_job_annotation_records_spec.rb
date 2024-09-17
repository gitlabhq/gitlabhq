# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillNullProjectCiJobAnnotationRecords,
  migration: :gitlab_ci,
  feature_category: :job_artifacts,
  migration_version: 20240826081110 do
  let(:connection) { Ci::ApplicationRecord.connection }
  let(:builds_table) { table(:p_ci_builds, database: :ci, primary_key: :id) }
  let(:annotations_table) { table(:p_ci_job_annotations, database: :ci, primary_key: :id) }

  let(:build1) { builds_table.create!(name: "build", project_id: 1, partition_id: 100) }
  let(:build2) { builds_table.create!(name: "build", project_id: 2, partition_id: 100) }

  let!(:annotations1) do
    annotations_table.create!(
      name: "annotations1",
      job_id: build1.id,
      partition_id: 100,
      project_id: -1)
  end

  let!(:annotations2) do
    annotations_table.create!(
      name: "annotations2",
      job_id: build2.id,
      partition_id: 100,
      project_id: -1)
  end

  describe '#up' do
    it 'backfills when annotations without project' do
      expect { migrate! }
        .to change { annotations1.reload.project_id }.to(build1.project_id)
        .and change { annotations2.reload.project_id }.to(build2.project_id)
    end
  end
end
