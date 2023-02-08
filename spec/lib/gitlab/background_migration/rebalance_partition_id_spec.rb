# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::RebalancePartitionId,
  :migration,
  schema: 20230125093723,
  feature_category: :continuous_integration do
  let(:ci_builds_table) { table(:ci_builds, database: :ci) }
  let(:ci_pipelines_table) { table(:ci_pipelines, database: :ci) }

  let!(:valid_ci_pipeline) { ci_pipelines_table.create!(id: 1, partition_id: 100) }
  let!(:invalid_ci_pipeline) { ci_pipelines_table.create!(id: 2, partition_id: 101) }

  describe '#perform' do
    using RSpec::Parameterized::TableSyntax

    where(:table_name, :invalid_record, :valid_record) do
      :ci_pipelines | invalid_ci_pipeline | valid_ci_pipeline
    end

    subject(:perform) do
      described_class.new(
        start_id: 1,
        end_id: 2,
        batch_table: table_name,
        batch_column: :id,
        sub_batch_size: 1,
        pause_ms: 0,
        connection: Ci::ApplicationRecord.connection
      ).perform
    end

    shared_examples 'fix invalid records' do
      it 'rebalances partition_id to 100 when partition_id is 101' do
        expect { perform }
          .to change { invalid_record.reload.partition_id }.from(101).to(100)
          .and not_change { valid_record.reload.partition_id }
      end
    end

    with_them do
      it_behaves_like 'fix invalid records'
    end
  end
end
