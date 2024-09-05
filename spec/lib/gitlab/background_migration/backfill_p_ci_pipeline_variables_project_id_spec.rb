# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillPCiPipelineVariablesProjectId, migration: :gitlab_ci, feature_category: :continuous_integration do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :p_ci_pipeline_variables }
    let(:backfill_column) { :project_id }
    let(:backfill_via_table) { :p_ci_pipelines }
    let(:backfill_via_column) { :project_id }
    let(:backfill_via_foreign_key) { :pipeline_id }
    let(:partition_column) { :partition_id }
  end
end
