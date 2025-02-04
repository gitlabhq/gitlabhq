# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillDastPreScanVerificationStepsProjectId,
  feature_category: :dynamic_application_security_testing,
  schema: 20250203154150,
  migration: :gitlab_sec do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :dast_pre_scan_verification_steps }
    let(:backfill_column) { :project_id }
    let(:backfill_via_table) { :dast_pre_scan_verifications }
    let(:backfill_via_column) { :project_id }
    let(:backfill_via_foreign_key) { :dast_pre_scan_verification_id }
  end
end
