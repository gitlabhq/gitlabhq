# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillPCiPipelineArtifactStatesProjectId,
  feature_category: :geo_replication,
  schema: 20260224223208,
  migration: :gitlab_ci do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :p_ci_pipeline_artifact_states }
    let(:batch_column) { :pipeline_artifact_id }
    let(:backfill_column) { :project_id }
    let(:backfill_via_table) { :ci_pipeline_artifacts }
    let(:backfill_via_column) { :project_id }
    let(:backfill_via_foreign_key) { :pipeline_artifact_id }
  end
end
