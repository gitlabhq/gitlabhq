# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillCiJobArtifactStatesProjectId,
  feature_category: :geo_replication,
  schema: 20240912122437,
  migration: :gitlab_ci do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :ci_job_artifact_states }
    let(:backfill_column) { :project_id }
    let(:batch_column) { :job_artifact_id }
    let(:backfill_via_table) { :p_ci_job_artifacts }
    let(:backfill_via_column) { :project_id }
    let(:backfill_via_foreign_key) { :job_artifact_id }
  end
end
