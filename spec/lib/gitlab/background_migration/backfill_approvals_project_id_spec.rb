# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillApprovalsProjectId,
  feature_category: :code_review_workflow,
  schema: 20240719090628 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :approvals }
    let(:backfill_column) { :project_id }
    let(:backfill_via_table) { :merge_requests }
    let(:backfill_via_column) { :target_project_id }
    let(:backfill_via_foreign_key) { :merge_request_id }
  end
end
