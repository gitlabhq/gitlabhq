# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillRequiredCodeOwnersSectionsProtectedBranchProjectId,
  feature_category: :source_code_management,
  schema: 20250205200238 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :required_code_owners_sections }
    let(:backfill_column) { :protected_branch_project_id }
    let(:backfill_via_table) { :protected_branches }
    let(:backfill_via_column) { :project_id }
    let(:backfill_via_foreign_key) { :protected_branch_id }
  end
end
