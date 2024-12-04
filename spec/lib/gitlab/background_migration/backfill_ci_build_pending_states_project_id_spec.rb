# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillCiBuildPendingStatesProjectId,
  feature_category: :continuous_integration,
  schema: 20241126151234,
  migration: :gitlab_ci do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :ci_build_pending_states }
    let(:backfill_column) { :project_id }
    let(:backfill_via_table) { :p_ci_builds }
    let(:backfill_via_column) { :project_id }
    let(:backfill_via_foreign_key) { :build_id }
    let(:partition_column) { :partition_id }
  end
end
