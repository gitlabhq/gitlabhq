# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe UpdateSubBatchSizeForMoveCiBuildsMetadata, migration: :gitlab_ci,
  feature_category: :continuous_integration do
  let(:table_name) { 'gitlab_partitions_dynamic.ci_builds_101' }
  let!(:migration) do
    Gitlab::Database::BackgroundMigration::BatchedMigration.create!(
      job_class_name: 'MoveCiBuildsMetadata',
      table_name: table_name,
      column_name: :id,
      job_arguments: ['partition_id', [101]],
      interval: 120,
      min_value: 1,
      max_value: 2,
      batch_size: 1000,
      sub_batch_size: 100,
      pause_ms: 100,
      gitlab_schema: :gitlab_ci,
      status: 1,
      total_tuple_count: 12345
    )
  end

  before do
    Ci::ApplicationRecord.connection.execute(<<~SQL)
      CREATE TABLE IF NOT EXISTS #{table_name} PARTITION OF p_ci_builds FOR VALUES IN (101);
    SQL
  end

  describe '#up' do
    context 'when on .com_except_jh' do
      before do
        allow(Gitlab).to receive(:com_except_jh?).and_return(true)
      end

      it 'updates the sub_batch_size to 250' do
        expect { migrate! }.to change { migration.reload.sub_batch_size }.from(100).to(250)
      end

      context 'when migration does not exist' do
        before do
          migration.delete
        end

        it 'does not raise an error' do
          expect { migrate! }.not_to raise_error
        end
      end
    end

    context 'when not on .com_except_jh' do
      before do
        allow(Gitlab).to receive(:com_except_jh?).and_return(false)
      end

      it 'does not update the migration' do
        expect { migrate! }.not_to change { migration.reload.sub_batch_size }
      end
    end
  end

  describe '#down' do
    context 'when on .com_except_jh' do
      before do
        allow(Gitlab).to receive(:com_except_jh?).and_return(true)
      end

      it 'reverts the sub_batch_size to 100' do
        migrate!
        expect { schema_migrate_down! }.to change { migration.reload.sub_batch_size }.from(250).to(100)
      end

      context 'when migration does not exist' do
        before do
          migration.delete
        end

        it 'does not raise an error' do
          expect { schema_migrate_down! }.not_to raise_error
        end
      end
    end

    context 'when not on .com_except_jh' do
      before do
        allow(Gitlab).to receive(:com_except_jh?).and_return(false)
      end

      it 'does not update the migration' do
        migrate!
        expect { schema_migrate_down! }.not_to change { migration.reload.sub_batch_size }
      end
    end
  end
end
