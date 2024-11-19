# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillCiTriggerRequestsProjectId, migration: :gitlab_ci, feature_category: :continuous_integration do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :ci_trigger_requests }
    let(:backfill_column) { :project_id }
    let(:backfill_via_table) { :ci_triggers }
    let(:backfill_via_column) { :project_id }
    let(:backfill_via_foreign_key) { :trigger_id }
  end
end
