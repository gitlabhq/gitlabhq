# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe QueueBackfillComplianceViolations, feature_category: :compliance_management do
  let(:migration) { described_class::MIGRATION }

  describe '#up' do
    it 'schedules background jobs for each batch of merge_request_compliance_violations' do
      migrate!

      expect(migration).to(
        have_scheduled_batched_migration(
          table_name: :merge_requests_compliance_violations,
          column_name: :id,
          interval: described_class::INTERVAL,
          batch_size: described_class::BATCH_SIZE
        )
      )
    end
  end

  describe '#down' do
    it 'deletes all batched migration records' do
      migrate!
      schema_migrate_down!

      expect(migration).not_to have_scheduled_batched_migration
    end
  end
end
