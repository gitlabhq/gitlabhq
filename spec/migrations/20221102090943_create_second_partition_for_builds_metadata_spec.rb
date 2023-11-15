# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe CreateSecondPartitionForBuildsMetadata, :migration, feature_category: :continuous_integration do
  let(:migration) { described_class.new }
  let(:partitions) { table(:ci_partitions) }

  describe '#up' do
    context 'when on sass' do
      before do
        allow(Gitlab).to receive(:com?).and_return(true)
      end

      it 'creates a new partition' do
        migrate!

        expect(partition_101_exists?).to be(true)
      end
    end

    context 'when self-managed' do
      before do
        allow(Gitlab).to receive(:com?).and_return(false)
      end

      it 'does not create the partition' do
        expect { migrate! }.not_to change { partition_101_exists? }
      end
    end
  end

  describe '#down' do
    context 'when on sass' do
      before do
        allow(Gitlab).to receive(:com?).and_return(true)
      end

      it 'removes the partition' do
        migrate!

        expect { migration.down }.to change { partition_101_exists? }.to(false)
      end
    end

    context 'when self-managed' do
      before do
        allow(Gitlab).to receive(:com?).and_return(false)
      end

      it 'does not change the partitions count' do
        migrate!

        expect { migration.down }.not_to change { partition_101_exists? }
      end
    end
  end

  def partition_101_exists?
    Gitlab::Database::PostgresPartition
      .for_parent_table(:p_ci_builds_metadata)
      .where(name: :ci_builds_metadata_101).any?
  end
end
