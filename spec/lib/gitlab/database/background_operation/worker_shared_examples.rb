# frozen_string_literal: true

RSpec.shared_examples 'background operation worker functionality' do |worker_factory|
  using RSpec::Parameterized::TableSyntax

  it { is_expected.to be_a Gitlab::Database::SharedModel }

  describe 'associations' do
    it { is_expected.to have_many(:jobs).inverse_of(:worker) }
  end

  describe 'validations' do
    subject { build(worker_factory) }

    described_class::REQUIRED_COLUMNS.each do |column|
      it { is_expected.to validate_presence_of(column) }
    end

    it { is_expected.to validate_numericality_of(:pause_ms).is_greater_than_or_equal_to(100) }
    it { is_expected.to validate_uniqueness_of(:job_arguments).scoped_to(:job_class_name, :table_name, :column_name) }
  end

  describe 'scopes' do
    let_it_be(:queued_worker) { create(worker_factory, :queued) }
    let_it_be(:active_worker) { create(worker_factory, :active) }
    let_it_be(:paused_worker) { create(worker_factory, :paused) }
    let_it_be(:finished_worker) { create(worker_factory, :finished) }

    let(:executable_workers) { [queued_worker, active_worker, paused_worker] }

    describe '.executable' do
      it 'returns workers with queued, active or paused status' do
        expect(described_class.executable).to match_array(executable_workers)
      end
    end

    describe '.executables_with_config' do
      let(:config) do
        {
          job_class_name: 'CustomJobClass',
          table_name: 'users',
          column_name: 'id',
          job_arguments: active_worker.job_arguments
        }
      end

      before do
        active_worker.update!(**config)
      end

      it 'returns executable workers with the given configurations' do
        extra_param = if worker_factory == :background_operation_worker
                        { org_id: active_worker.organization_id }
                      else
                        {}
                      end

        expect(described_class.executables_with_config(*config.values, **extra_param))
          .to match_array([active_worker])
      end
    end
  end

  describe 'sliding_list partitioning' do
    let(:connection) { described_class.connection }
    let(:partition_manager) { Gitlab::Database::Partitioning::PartitionManager.new(described_class) }

    describe 'next_partition_if callback' do
      let(:active_partition) { described_class.partitioning_strategy.active_partition }

      subject(:value) { described_class.partitioning_strategy.next_partition_if.call(active_partition) }

      context 'when the partition is empty' do
        it { is_expected.to be(false) }
      end

      context 'when the partition has recent records' do
        before do
          create(worker_factory, created_at: 1.day.ago)
        end

        it { is_expected.to be(false) }
      end

      context 'when the first record of the partition is older than PARTITION_DURATION' do
        before do
          create(worker_factory, created_at: (described_class::PARTITION_DURATION + 1.day).ago)
          create(worker_factory, created_at: 1.day.ago)
        end

        it { is_expected.to be(true) }
      end
    end

    describe 'detach_partition_if callback' do
      let(:active_partition) { described_class.partitioning_strategy.active_partition }

      subject(:value) { described_class.partitioning_strategy.detach_partition_if.call(active_partition) }

      context 'when the partition contains executable workers' do
        before do
          create(worker_factory, :active)
          create(worker_factory, :paused)
          create(worker_factory, :finished)
        end

        it { is_expected.to be(false) }
      end

      context 'when the partition contains only non-executable workers' do
        before do
          create(worker_factory, :finished)
          create(worker_factory, :failed)
        end

        it { is_expected.to be(true) }
      end

      context 'when the partition is empty' do
        it { is_expected.to be(true) }
      end
    end

    describe 'the behavior of the strategy' do
      it 'moves records to new partitions as time passes', :freeze_time do
        # We start with partition 1
        expect(described_class.partitioning_strategy.current_partitions.map(&:value)).to match_array([1])

        # it's not 14 days old yet so no new partitions are created
        partition_manager.sync_partitions

        expect(described_class.partitioning_strategy.current_partitions.map(&:value)).to match_array([1])

        # add one record so the next partition will be created
        create(worker_factory) # rubocop:disable Rails/SaveBang -- factory

        # after traveling forward past PARTITION_DURATION
        travel(described_class::PARTITION_DURATION + 1.minute)

        # a new partition is created
        partition_manager.sync_partitions

        expect(described_class.partitioning_strategy.current_partitions.map(&:value)).to match_array([1, 2])

        # and we can insert to the new partition
        expect { create(worker_factory) }.not_to raise_error # rubocop:disable Rails/SaveBang -- factory

        # after marking old records as non-executable
        described_class.for_partition(1).update_all(status: 3)

        partition_manager.sync_partitions

        # the old one is removed
        expect(described_class.partitioning_strategy.current_partitions.map(&:value)).to match_array([2])

        # and we only have the newly created partition left.
        expect(described_class.count).to eq(1)
      end
    end
  end
end
