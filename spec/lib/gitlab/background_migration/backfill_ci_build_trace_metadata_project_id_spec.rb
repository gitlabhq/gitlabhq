# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillCiBuildTraceMetadataProjectId,
  feature_category: :continuous_integration, migration: :gitlab_ci do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :p_ci_build_trace_metadata }
    let(:batch_column) { :build_id }
    let(:backfill_column) { :project_id }
    let(:backfill_via_table) { :p_ci_builds }
    let(:backfill_via_column) { :project_id }
    let(:backfill_via_foreign_key) { :build_id }
    let(:partition_column) { :partition_id }
  end
end
