# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RequeueBackfillAdminModeScopeForPersonalAccessTokens, feature_category: :system_access do
  describe '#up' do
    it 'schedules background migration' do
      migrate!

      expect(described_class::MIGRATION).to(
        have_scheduled_batched_migration(
          table_name: :personal_access_tokens,
          column_name: :id,
          interval: described_class::DELAY_INTERVAL)
      )
    end
  end
end
