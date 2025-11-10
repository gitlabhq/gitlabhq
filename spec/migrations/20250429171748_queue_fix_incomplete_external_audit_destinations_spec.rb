# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe QueueFixIncompleteExternalAuditDestinations,
  migration: :gitlab_main,
  feature_category: :audit_events do
  let(:batched_migration) { described_class::MIGRATION }

  it 'is a no-op migration' do
    # Simply verify that up and down do nothing
    expect { migrate! }.not_to change { Gitlab::Database::BackgroundMigration::BatchedMigration.count }

    expect { schema_migrate_down! }.not_to change { Gitlab::Database::BackgroundMigration::BatchedMigration.count }
  end
end
