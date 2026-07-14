# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe FinalizeMoveCiBuildsMetadata, migration: :gitlab_ci,
  feature_category: :continuous_integration do
  let(:batched_background_migration) { table(:batched_background_migrations) }

  let!(:migration) do
    batched_background_migration.create!(
      job_class_name: 'MoveCiBuildsMetadata',
      table_name: 'gitlab_partitions_dynamic.ci_builds_views_100_1',
      column_name: :id,
      job_arguments: ['partition_id', [100]],
      batch_size: 1_000,
      sub_batch_size: 250,
      interval: 120,
      gitlab_schema: :gitlab_ci,
      min_value: 1,
      max_value: 2,
      status: 3 # Finished
    )
  end

  context 'when on .com_except_jh' do
    before do
      allow(Gitlab).to receive(:com_except_jh?).and_return(true)
    end

    it 'finalizes the batched background migration', :aggregate_failures do
      reversible_migration do |migration_runner|
        migration_runner.after -> {
          expect(migration.reload.status).to eq(6) # Finalized
        }
      end
    end
  end

  context 'when not on .com_except_jh' do
    before do
      allow(Gitlab).to receive(:com_except_jh?).and_return(false)
    end

    it 'does not finalize the batched background migration' do
      expect { migrate! }.not_to change { migration.reload.status }.from(3)
    end
  end
end
