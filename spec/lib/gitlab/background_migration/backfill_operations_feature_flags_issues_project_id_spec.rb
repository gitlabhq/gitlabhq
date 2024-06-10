# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillOperationsFeatureFlagsIssuesProjectId,
  feature_category: :feature_flags,
  schema: 20240607104312 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :operations_feature_flags_issues }
    let(:backfill_column) { :project_id }
    let(:backfill_via_table) { :operations_feature_flags }
    let(:backfill_via_column) { :project_id }
    let(:backfill_via_foreign_key) { :feature_flag_id }
  end
end
