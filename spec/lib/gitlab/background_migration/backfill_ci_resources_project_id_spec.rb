# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillCiResourcesProjectId,
  feature_category: :continuous_integration,
  schema: 20240930154300,
  migration: :gitlab_ci do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :ci_resources }
    let(:backfill_column) { :project_id }
    let(:backfill_via_table) { :ci_resource_groups }
    let(:backfill_via_column) { :project_id }
    let(:backfill_via_foreign_key) { :resource_group_id }
  end
end
