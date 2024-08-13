# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::FinishedPipelineChSyncEvent, type: :model, feature_category: :fleet_visibility do
  describe 'validations' do
    subject(:event) do
      described_class.create!(pipeline_id: 1, pipeline_finished_at: 2.hours.ago, project_namespace_id: 1)
    end

    it { is_expected.to validate_presence_of(:pipeline_id) }
    it { is_expected.to validate_presence_of(:pipeline_finished_at) }
    it { is_expected.to validate_presence_of(:project_namespace_id) }
  end

  describe '.for_partition', :freeze_time do
    subject(:scope) { described_class.for_partition(partition) }

    let_it_be(:partition_manager) { Gitlab::Database::Partitioning::PartitionManager.new(described_class) }

    around do |example|
      Gitlab::Database::SharedModel.using_connection(Ci::ApplicationRecord.connection) do
        example.run
      end
    end

    before do
      described_class.create!(pipeline_id: 1, pipeline_finished_at: 2.hours.ago, project_namespace_id: 1,
        processed: true)
      described_class.create!(pipeline_id: 2, pipeline_finished_at: 1.hour.ago, project_namespace_id: 1,
        processed: true)

      travel(described_class::PARTITION_DURATION + 1.second)

      partition_manager.sync_partitions
      described_class.create!(pipeline_id: 3, pipeline_finished_at: 1.hour.ago, project_namespace_id: 1)
    end

    context 'when partition = 1' do
      let(:partition) { 1 }

      it { is_expected.to match_array(described_class.where(pipeline_id: [1, 2])) }
    end

    context 'when partition = 2' do
      let(:partition) { 2 }

      it { is_expected.to match_array(described_class.where(pipeline_id: 3)) }
    end
  end

  describe 'sliding_list partitioning' do
    let(:partition_manager) { Gitlab::Database::Partitioning::PartitionManager.new(described_class) }
    let(:partitioning_strategy) { described_class.partitioning_strategy }

    around do |example|
      Gitlab::Database::SharedModel.using_connection(Ci::ApplicationRecord.connection) do
        example.run
      end
    end

    describe 'next_partition_if callback' do
      let(:active_partition) { partitioning_strategy.active_partition }

      subject(:value) { partitioning_strategy.next_partition_if.call(active_partition) }

      context 'when the partition is empty' do
        it { is_expected.to eq(false) }
      end

      context 'when the partition has records' do
        before do
          described_class.create!(pipeline_id: 1, pipeline_finished_at: 2.hours.ago, project_namespace_id: 1,
            processed: true)
          described_class.create!(pipeline_id: 2, pipeline_finished_at: 1.minute.ago, project_namespace_id: 1)
        end

        it { is_expected.to eq(false) }
      end

      context 'when the first record of the partition is older than PARTITION_DURATION' do
        before do
          described_class.create!(
            pipeline_id: 2, pipeline_finished_at: 1.second.after(described_class::PARTITION_DURATION.ago),
            project_namespace_id: 1)
          described_class.create!(
            pipeline_id: 1, pipeline_finished_at: 1.second.before(described_class::PARTITION_DURATION.ago),
            project_namespace_id: 1)
        end

        it { is_expected.to eq(true) }
      end
    end

    describe 'detach_partition_if callback' do
      let(:active_partition) { partitioning_strategy.active_partition }

      subject(:value) { partitioning_strategy.detach_partition_if.call(active_partition) }

      context 'when the partition is empty' do
        it { is_expected.to eq(true) }
      end

      context 'when the partition contains unprocessed records' do
        before do
          travel_to DateTime.new(2023, 12, 10) # use fixed date to avoid leap day failures

          described_class.create!(pipeline_id: 1, pipeline_finished_at: 2.hours.ago, project_namespace_id: 1,
            processed: true)
          described_class.create!(pipeline_id: 2, pipeline_finished_at: 10.minutes.ago, project_namespace_id: 1)
          described_class.create!(pipeline_id: 3, pipeline_finished_at: 1.minute.ago, project_namespace_id: 1)
        end

        it { is_expected.to eq(false) }

        context 'when almost all the records are too old' do
          before do
            travel(30.days - 2.minutes)
          end

          it { is_expected.to eq(false) }
        end

        context 'when all the records are too old' do
          before do
            travel(30.days)
          end

          it { is_expected.to eq(true) }
        end
      end

      context 'when the partition contains only processed records' do
        before do
          described_class.create!(pipeline_id: 1, pipeline_finished_at: 2.hours.ago, processed: true,
            project_namespace_id: 1)
          described_class.create!(pipeline_id: 2, pipeline_finished_at: 1.minute.ago, processed: true,
            project_namespace_id: 1)
        end

        it { is_expected.to eq(true) }
      end
    end

    describe 'the behavior of the strategy' do
      it 'moves records to new partitions as time passes', :freeze_time do
        # We start with partition 1
        expect(partitioning_strategy.current_partitions.map(&:value)).to contain_exactly(1)

        # it's not a day old yet so no new partitions are created
        partition_manager.sync_partitions

        expect(partitioning_strategy.current_partitions.map(&:value)).to contain_exactly(1)

        # add one record so the next partition will be created
        described_class.create!(pipeline_id: 1, pipeline_finished_at: Time.current, project_namespace_id: 1)

        # after traveling forward a day
        travel(described_class::PARTITION_DURATION + 1.second)

        # a new partition is created
        partition_manager.sync_partitions

        expect(partitioning_strategy.current_partitions.map(&:value)).to contain_exactly(1, 2)

        # and we can insert to the new partition
        expect do
          described_class.create!(pipeline_id: 5, pipeline_finished_at: Time.current, project_namespace_id: 1)
        end.not_to raise_error

        # after processing old records
        described_class.for_partition([1, 2]).update_all(processed: true)

        partition_manager.sync_partitions

        # the old one is removed
        expect(partitioning_strategy.current_partitions.map(&:value)).to contain_exactly(2)

        # and we only have the newly created partition left.
        expect(described_class.count).to eq(1)
      end
    end
  end

  context 'with existing events' do
    let_it_be(:event3) do
      described_class.create!(pipeline_id: 3, pipeline_finished_at: 2.hours.ago, project_namespace_id: 1,
        processed: true)
    end

    let_it_be(:event1) do
      described_class.create!(pipeline_id: 1, pipeline_finished_at: 1.hour.ago, project_namespace_id: 1)
    end

    let_it_be(:event2) do
      described_class.create!(pipeline_id: 2, pipeline_finished_at: 1.hour.ago, project_namespace_id: 1,
        processed: true)
    end

    describe 'sorting' do
      describe '.order_by_pipeline_id' do
        subject(:scope) { described_class.order_by_pipeline_id }

        it { is_expected.to eq([event1, event2, event3]) }
      end
    end

    describe 'scopes' do
      describe '.pending' do
        subject(:scope) { described_class.pending }

        it { is_expected.to contain_exactly(event1) }
      end
    end
  end
end
