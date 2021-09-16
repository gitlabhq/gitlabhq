# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Partitioning do
  describe '.sync_partitions' do
    let(:partition_manager_class) { described_class::MultiDatabasePartitionManager }
    let(:partition_manager) { double('partition manager') }

    context 'when no partitioned models are given' do
      it 'calls the partition manager with the registered models' do
        expect(partition_manager_class).to receive(:new)
          .with(described_class.registered_models)
          .and_return(partition_manager)

        expect(partition_manager).to receive(:sync_partitions)

        described_class.sync_partitions
      end
    end

    context 'when partitioned models are given' do
      it 'calls the partition manager with the given models' do
        models = ['my special model']

        expect(partition_manager_class).to receive(:new)
          .with(models)
          .and_return(partition_manager)

        expect(partition_manager).to receive(:sync_partitions)

        described_class.sync_partitions(models)
      end
    end
  end
end
