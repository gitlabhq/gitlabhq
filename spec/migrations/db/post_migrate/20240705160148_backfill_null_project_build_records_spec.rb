# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillNullProjectBuildRecords, migration: :gitlab_ci, feature_category: :database do
  let!(:pipeline_with_project) do
    table(:ci_pipelines, primary_key: :id, database: :ci).create!(project_id: 10, partition_id: 100)
  end

  let(:builds_table) { table(:p_ci_builds, database: :ci) }
  let!(:build_to_be_backfilled) do
    builds_table.create!(name: "backfilled", commit_id: pipeline_with_project.id, partition_id: 100)
  end

  let!(:build_with_project_id) { builds_table.create!(name: "standard", project_id: 11, partition_id: 100) }
  let!(:build_invalid_backfill) { builds_table.create!(name: "deleted", partition_id: 100) }

  describe '#up' do
    it 'backfills when applicable otherwise deletes' do
      migrate!

      expect(builds_table.where(name: build_to_be_backfilled.name).first.project_id).to eq(10)
      expect(builds_table.where(name: build_with_project_id.name).first.project_id).to eq(11)
      expect(builds_table.where(name: build_invalid_backfill.name)).to be_empty
    end
  end
end
