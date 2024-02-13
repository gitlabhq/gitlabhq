# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe DeleteOrphansApprovalProjectRules2, feature_category: :security_policy_management do
  describe '#up' do
    it 'schedules background migration for project approval rules' do
      migrate!

      expect(described_class::PROJECT_MIGRATION).to have_scheduled_batched_migration(
        table_name: :approval_project_rules,
        column_name: :id,
        interval: described_class::INTERVAL)
    end
  end
end
