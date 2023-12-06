# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Catalog::Resources::SyncEvent, type: :model, feature_category: :pipeline_composition do
  let_it_be_with_reload(:project1) { create(:project) }
  let_it_be_with_reload(:project2) { create(:project) }
  let_it_be(:resource1) { create(:ci_catalog_resource, project: project1) }

  it { is_expected.to belong_to(:catalog_resource).class_name('Ci::Catalog::Resource') }
  it { is_expected.to belong_to(:project) }

  describe 'PG triggers' do
    context 'when the associated project of a catalog resource is updated' do
      context 'when project name is updated' do
        it 'creates a sync event record' do
          expect do
            project1.update!(name: 'New name')
          end.to change { described_class.count }.by(1)
        end
      end

      context 'when project description is updated' do
        it 'creates a sync event record' do
          expect do
            project1.update!(description: 'New description')
          end.to change { described_class.count }.by(1)
        end
      end

      context 'when project visibility_level is updated' do
        it 'creates a sync event record' do
          expect do
            project1.update!(visibility_level: Gitlab::VisibilityLevel::INTERNAL)
          end.to change { described_class.count }.by(1)
        end
      end
    end

    context 'when a project without an associated catalog resource is updated' do
      it 'does not create a sync event record' do
        expect do
          project2.update!(name: 'New name')
        end.not_to change { described_class.count }
      end
    end
  end

  describe 'when there are sync event records' do
    let_it_be(:resource2) { create(:ci_catalog_resource, project: project2) }

    before_all do
      create(:ci_catalog_resource_sync_event, catalog_resource: resource1, status: :processed)
      create(:ci_catalog_resource_sync_event, catalog_resource: resource1)
      create_list(:ci_catalog_resource_sync_event, 2, catalog_resource: resource2)
    end

    describe '.unprocessed_events' do
      it 'returns the events in pending status' do
        # 1 pending event from resource1 + 2 pending events from resource2
        expect(described_class.unprocessed_events.size).to eq(3)
      end

      it 'selects the partition attribute in the result' do
        described_class.unprocessed_events.each do |event|
          expect(event.partition).not_to be_nil
        end
      end
    end

    describe '.mark_records_processed' do
      it 'updates the records to processed status' do
        expect(described_class.status_pending.count).to eq(3)
        expect(described_class.status_processed.count).to eq(1)

        described_class.mark_records_processed(described_class.unprocessed_events)

        expect(described_class.pluck(:status).uniq).to eq(['processed'])

        expect(described_class.status_pending.count).to eq(0)
        expect(described_class.status_processed.count).to eq(4)
      end
    end
  end

  describe '.upper_bound_count' do
    it 'returns 0 when there are no records in the table' do
      expect(described_class.upper_bound_count).to eq(0)
    end

    it 'returns an estimated number of unprocessed records' do
      create_list(:ci_catalog_resource_sync_event, 5, catalog_resource: resource1)
      described_class.order(:id).limit(2).update_all(status: :processed)

      expect(described_class.upper_bound_count).to eq(3)
    end
  end

  describe 'sliding_list partitioning' do
    let(:partition_manager) { Gitlab::Database::Partitioning::PartitionManager.new(described_class) }

    describe 'next_partition_if callback' do
      let(:active_partition) { described_class.partitioning_strategy.active_partition }

      subject(:value) { described_class.partitioning_strategy.next_partition_if.call(active_partition) }

      context 'when the partition is empty' do
        it { is_expected.to eq(false) }
      end

      context 'when the partition has records' do
        before do
          create(:ci_catalog_resource_sync_event, catalog_resource: resource1, status: :processed)
          create(:ci_catalog_resource_sync_event, catalog_resource: resource1)
        end

        it { is_expected.to eq(false) }
      end

      context 'when the first record of the partition is older than PARTITION_DURATION' do
        before do
          create(:ci_catalog_resource_sync_event, catalog_resource: resource1)
          described_class.first.update!(created_at: (described_class::PARTITION_DURATION + 1.day).ago)
        end

        it { is_expected.to eq(true) }
      end
    end

    describe 'detach_partition_if callback' do
      let(:active_partition) { described_class.partitioning_strategy.active_partition }

      subject(:value) { described_class.partitioning_strategy.detach_partition_if.call(active_partition) }

      before_all do
        create(:ci_catalog_resource_sync_event, catalog_resource: resource1, status: :processed)
        create(:ci_catalog_resource_sync_event, catalog_resource: resource1)
      end

      context 'when the partition contains unprocessed records' do
        it { is_expected.to eq(false) }
      end

      context 'when the partition contains only processed records' do
        before do
          described_class.update_all(status: :processed)
        end

        it { is_expected.to eq(true) }
      end
    end

    describe 'strategy behavior' do
      it 'moves records to new partitions as time passes', :freeze_time do
        # We start with partition 1
        expect(described_class.partitioning_strategy.current_partitions.map(&:value)).to eq([1])

        # Add one record so the initial partition is not empty
        create(:ci_catalog_resource_sync_event, catalog_resource: resource1)

        # It's not a day old yet so no new partitions are created
        partition_manager.sync_partitions

        expect(described_class.partitioning_strategy.current_partitions.map(&:value)).to eq([1])

        # After traveling forward a day
        travel(described_class::PARTITION_DURATION + 1.second)

        # a new partition is created
        partition_manager.sync_partitions

        expect(described_class.partitioning_strategy.current_partitions.map(&:value)).to contain_exactly(1, 2)

        # and we can insert to the new partition
        create(:ci_catalog_resource_sync_event, catalog_resource: resource1)

        # After processing records in partition 1
        described_class.mark_records_processed(described_class.for_partition(1).select_with_partition)

        partition_manager.sync_partitions

        # partition 1 is removed
        expect(described_class.partitioning_strategy.current_partitions.map(&:value)).to eq([2])

        # and we only have the newly created partition left.
        expect(described_class.count).to eq(1)
      end
    end
  end
end
