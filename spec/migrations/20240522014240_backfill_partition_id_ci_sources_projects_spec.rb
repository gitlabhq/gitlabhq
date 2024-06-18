# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillPartitionIdCiSourcesProjects, migration: :gitlab_ci, feature_category: :continuous_integration do
  let!(:pipeline_101) do
    table(:ci_pipelines).create!(id: 1, partition_id: 101)
  end

  let!(:pipeline_102) do
    table(:ci_pipelines).create!(id: 2, partition_id: 102)
  end

  let!(:sources_project1) do
    table(:ci_sources_projects).create!(id: 1, pipeline_id: pipeline_101.id, source_project_id: 1, partition_id: 100)
  end

  let!(:sources_project2) do
    table(:ci_sources_projects).create!(id: 2, pipeline_id: pipeline_102.id, source_project_id: 1, partition_id: 100)
  end

  describe '#up' do
    it 'sets the partition_id', :aggregate_failures do
      expect { migrate! }
        .to change { sources_project1.reload.partition_id }.from(100).to(pipeline_101.partition_id)
        .and change { sources_project2.reload.partition_id }.from(100).to(pipeline_102.partition_id)
    end
  end
end
