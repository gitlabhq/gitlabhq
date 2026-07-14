# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillCiRunnersUuid,
  feature_category: :runner_core do
  let(:ci_runners) { table(:ci_runners, database: :ci, primary_key: :id) }

  let!(:runner_without_uuid_1) { ci_runners.create!(runner_type: 1, uuid: nil) }
  let!(:runner_without_uuid_2) { ci_runners.create!(runner_type: 1, uuid: nil) }
  let!(:runner_with_uuid) do
    ci_runners.create!(runner_type: 1, uuid: '01966aa0-f383-7a6b-b694-cd4f2f96cca1')
  end

  let(:migration_args) do
    {
      start_id: ci_runners.minimum(:id),
      end_id: ci_runners.maximum(:id),
      batch_table: :ci_runners,
      batch_column: :id,
      sub_batch_size: 100,
      pause_ms: 0,
      connection: Ci::ApplicationRecord.connection
    }
  end

  subject(:perform_migration) { described_class.new(**migration_args).perform }

  describe '#perform' do
    it 'backfills uuid for runners that lack it' do
      perform_migration

      expect(runner_without_uuid_1.reload.uuid).to be_present
      expect(runner_without_uuid_2.reload.uuid).to be_present
    end

    it 'assigns a unique uuid to each runner' do
      perform_migration

      expect(runner_without_uuid_1.reload.uuid).not_to eq(runner_without_uuid_2.reload.uuid)
    end

    it 'does not overwrite existing uuids' do
      expect { perform_migration }
        .not_to change { runner_with_uuid.reload.uuid }
    end

    it 'is idempotent' do
      perform_migration
      first_uuid = runner_without_uuid_1.reload.uuid

      perform_migration

      expect(runner_without_uuid_1.reload.uuid).to eq(first_uuid)
    end
  end
end
