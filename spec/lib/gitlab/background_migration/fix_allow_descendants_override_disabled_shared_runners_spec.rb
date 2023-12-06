# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::FixAllowDescendantsOverrideDisabledSharedRunners, schema: 20230802085923,
  feature_category: :fleet_visibility do
  let(:namespaces) { table(:namespaces) }

  let!(:valid_enabled) do
    namespaces.create!(name: 'valid_enabled', path: 'valid_enabled',
      shared_runners_enabled: true,
      allow_descendants_override_disabled_shared_runners: false)
  end

  let!(:invalid_enabled) do
    namespaces.create!(name: 'invalid_enabled', path: 'invalid_enabled',
      shared_runners_enabled: true,
      allow_descendants_override_disabled_shared_runners: true)
  end

  let!(:disabled_and_overridable) do
    namespaces.create!(name: 'disabled_and_overridable', path: 'disabled_and_overridable',
      shared_runners_enabled: false,
      allow_descendants_override_disabled_shared_runners: true)
  end

  let!(:disabled_and_unoverridable) do
    namespaces.create!(name: 'disabled_and_unoverridable', path: 'disabled_and_unoverridable',
      shared_runners_enabled: false,
      allow_descendants_override_disabled_shared_runners: false)
  end

  let(:migration_attrs) do
    {
      start_id: namespaces.minimum(:id),
      end_id: namespaces.maximum(:id),
      batch_table: :namespaces,
      batch_column: :id,
      sub_batch_size: 2,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    }
  end

  it 'fixes invalid allow_descendants_override_disabled_shared_runners and does not affect others' do
    expect do
      described_class.new(**migration_attrs).perform
    end.to change { invalid_enabled.reload.allow_descendants_override_disabled_shared_runners }.from(true).to(false)
      .and not_change { valid_enabled.reload.allow_descendants_override_disabled_shared_runners }.from(false)
      .and not_change { disabled_and_overridable.reload.allow_descendants_override_disabled_shared_runners }.from(true)
      .and not_change { disabled_and_unoverridable.reload.allow_descendants_override_disabled_shared_runners }
         .from(false)
  end
end
