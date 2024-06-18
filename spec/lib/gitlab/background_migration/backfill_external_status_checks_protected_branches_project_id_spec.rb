# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillExternalStatusChecksProtectedBranchesProjectId,
  feature_category: :compliance_management,
  schema: 20240613153405 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :external_status_checks_protected_branches }
    let(:backfill_column) { :project_id }
    let(:backfill_via_table) { :external_status_checks }
    let(:backfill_via_column) { :project_id }
    let(:backfill_via_foreign_key) { :external_status_check_id }
  end
end
