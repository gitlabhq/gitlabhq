# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe DeleteOrphansApprovalRules, feature_category: :source_code_management do
  describe '#up' do
    it 'schedules background migration for both levels of approval rules' do
      migrate!

      expect(described_class::MERGE_REQUEST_MIGRATION).to have_scheduled_batched_migration(
        table_name: :approval_merge_request_rules,
        column_name: :id,
        interval: described_class::INTERVAL)

      expect(described_class::PROJECT_MIGRATION).to have_scheduled_batched_migration(
        table_name: :approval_project_rules,
        column_name: :id,
        interval: described_class::INTERVAL)
    end
  end
end
