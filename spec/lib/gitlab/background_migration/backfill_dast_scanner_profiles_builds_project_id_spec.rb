# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillDastScannerProfilesBuildsProjectId,
  feature_category: :dynamic_application_security_testing,
  schema: 20240930135259,
  migration: :gitlab_sec do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :dast_scanner_profiles_builds }
    let(:batch_column) { :ci_build_id }
    let(:backfill_column) { :project_id }
    let(:backfill_via_table) { :dast_scanner_profiles }
    let(:backfill_via_column) { :project_id }
    let(:backfill_via_foreign_key) { :dast_scanner_profile_id }
  end
end
