# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillCiPipelineScheduleVariablesProjectId,
  feature_category: :continuous_integration,
  schema: 20241003181428,
  migration: :gitlab_ci do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :ci_pipeline_schedule_variables }
    let(:backfill_column) { :project_id }
    let(:backfill_via_table) { :ci_pipeline_schedules }
    let(:backfill_via_column) { :project_id }
    let(:backfill_via_foreign_key) { :pipeline_schedule_id }
  end
end
