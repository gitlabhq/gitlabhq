# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe QueueResetStatusOnContainerRepositories, feature_category: :container_registry do
  let!(:batched_migration) { described_class::MIGRATION }

  before do
    stub_container_registry_config(
      enabled: true,
      api_url: 'http://example.com',
      key: 'spec/fixtures/x509_certificate_pk.key'
    )
  end

  it 'schedules a new batched migration' do
    reversible_migration do |migration|
      migration.before -> {
        expect(batched_migration).not_to have_scheduled_batched_migration
      }

      migration.after -> {
        expect(batched_migration).to have_scheduled_batched_migration(
          table_name: :container_repositories,
          column_name: :id,
          interval: described_class::DELAY_INTERVAL,
          sub_batch_size: described_class::BATCH_SIZE
        )
      }
    end
  end

  context 'with the container registry disabled' do
    before do
      allow(::Gitlab.config.registry).to receive(:enabled).and_return(false)
    end

    it 'does not schedule a new batched migration' do
      reversible_migration do |migration|
        migration.before -> {
          expect(batched_migration).not_to have_scheduled_batched_migration
        }

        migration.after -> {
          expect(batched_migration).not_to have_scheduled_batched_migration
        }
      end
    end
  end
end
