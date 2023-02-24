# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RescheduleExpireOAuthTokens, feature_category: :system_access do
  let!(:migration) { described_class::MIGRATION }

  describe '#up' do
    it 'schedules background jobs for each batch of oauth tokens' do
      migrate!

      expect(migration).to(
        have_scheduled_batched_migration(
          table_name: :oauth_access_tokens,
          column_name: :id,
          interval: described_class::INTERVAL
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
