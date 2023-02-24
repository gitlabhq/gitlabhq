# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe CleanupOAuthAccessTokensWithNullExpiresIn, feature_category: :system_access do
  let(:batched_migration) { described_class::MIGRATION }

  it 'schedules background jobs for each batch of oauth_access_tokens' do
    reversible_migration do |migration|
      migration.before -> {
        expect(batched_migration).not_to have_scheduled_batched_migration
      }

      migration.after -> {
        expect(batched_migration).to have_scheduled_batched_migration(
          table_name: :oauth_access_tokens,
          column_name: :id,
          interval: described_class::INTERVAL
        )
      }
    end
  end
end
