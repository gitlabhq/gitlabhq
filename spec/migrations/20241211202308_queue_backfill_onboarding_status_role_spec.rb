# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe QueueBackfillOnboardingStatusRole, migration: :gitlab_main, feature_category: :onboarding do
  it 'is a no-op migration' do
    expect { migrate! }.not_to change { Gitlab::Database::BackgroundMigration::BatchedMigration.count }

    expect { schema_migrate_down! }.not_to change { Gitlab::Database::BackgroundMigration::BatchedMigration.count }
  end
end
