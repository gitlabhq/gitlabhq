# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillCiUnitTestFailuresProjectId,
  feature_category: :code_testing,
  schema: 20240922144910,
  migration: :gitlab_ci do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :ci_unit_test_failures }
    let(:backfill_column) { :project_id }
    let(:backfill_via_table) { :ci_unit_tests }
    let(:backfill_via_column) { :project_id }
    let(:backfill_via_foreign_key) { :unit_test_id }
  end
end
