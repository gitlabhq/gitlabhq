# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillCiJobVariablesProjectId, feature_category: :continuous_integration, migration: :gitlab_ci, schema: 20240821074355 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :ci_job_variables }
    let(:backfill_column) { :project_id }
    let(:backfill_via_table) { :p_ci_builds }
    let(:backfill_via_column) { :project_id }
    let(:backfill_via_foreign_key) { :job_id }
  end
end
