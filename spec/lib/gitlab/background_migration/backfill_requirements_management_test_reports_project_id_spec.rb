# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillRequirementsManagementTestReportsProjectId,
  feature_category: :requirements_management,
  schema: 20250209005904 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :requirements_management_test_reports }
    let(:backfill_column) { :project_id }
    let(:backfill_via_table) { :issues }
    let(:backfill_via_column) { :project_id }
    let(:backfill_via_foreign_key) { :issue_id }
  end
end
