# frozen_string_literal: true

RSpec.shared_examples 'background operation job functionality' do |job_factory, worker_factory|
  using RSpec::Parameterized::TableSyntax

  it { is_expected.to be_a Gitlab::Database::SharedModel }

  specify do
    expect(described_class::TIMEOUT_EXCEPTIONS).to contain_exactly(
      ActiveRecord::StatementTimeout,
      ActiveRecord::ConnectionTimeoutError,
      ActiveRecord::AdapterTimeout,
      ActiveRecord::LockWaitTimeout,
      ActiveRecord::QueryCanceled
    )
  end

  describe 'associations' do
    let_it_be(:worker) { create(worker_factory) } # rubocop:disable Rails/SaveBang -- factory, not an AR object
    let_it_be(:job) { create(job_factory, worker: worker, worker_partition: worker.partition) }

    it { is_expected.to belong_to(:worker).inverse_of(:jobs) }

    it 'maintains inverse relationship with the worker' do
      expect(worker.jobs).to match_array([job])
      expect(job.worker).to eq(worker)
    end
  end

  describe 'validations' do
    subject { build(job_factory) }

    described_class::REQUIRED_COLUMNS.each do |column|
      it { is_expected.to validate_presence_of(column) }
    end

    it { is_expected.to validate_numericality_of(:pause_ms).is_greater_than_or_equal_to(100) }
  end

  describe 'scopes' do
    let_it_be(:job_1) { create(job_factory, :pending) }
    let_it_be(:job_2) { create(job_factory, :running) }
    let_it_be(:job_3) { create(job_factory, :failed, attempts: 3) }
    let_it_be(:job_4) { create(job_factory, :succeeded) }

    describe '.executable' do
      it 'returns jobs with only with pending or running status' do
        expect(described_class.executable).to contain_exactly(job_1, job_2)
      end
    end

    describe '.running' do
      it 'returns jobs with only with running status' do
        expect(described_class.running).to contain_exactly(job_2)
      end
    end

    describe '.failed' do
      it 'returns jobs with only with failed status' do
        expect(described_class.failed).to contain_exactly(job_3)
      end
    end

    describe '.created_since', :freeze_time do
      let(:cutoff_time) { 1.minute.from_now }
      let!(:job_5) { create(job_factory, created_at: 2.minutes.from_now) }

      it 'returns jobs created since the cutoff time' do
        expect(described_class.created_since(cutoff_time)).to contain_exactly(job_5)
      end
    end

    describe '.below_max_attempts' do
      before do
        job_4.update!(attempts: 2)
      end

      it 'returns jobs below max attempts' do
        expect(described_class.below_max_attempts).to contain_exactly(job_1, job_2, job_4)
      end
    end

    describe '.retriable' do
      before do
        job_3.update!(attempts: 2)
      end

      it 'returns jobs that are retriable' do
        expect(described_class.retriable).to contain_exactly(job_3)
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
          create(job_factory, created_at: 1.day.ago)
        end

        it { is_expected.to be(false) }
      end

      context 'when the first record of the partition is older than PARTITION_DURATION' do
        before do
          create(job_factory, created_at: (described_class::PARTITION_DURATION + 1.day).ago)
          create(job_factory, created_at: 1.day.ago)
        end

        it { is_expected.to be(true) }
      end
    end

    describe 'detach_partition_if callback' do
      let(:active_partition) { described_class.partitioning_strategy.active_partition }

      subject(:value) { described_class.partitioning_strategy.detach_partition_if.call(active_partition) }

      context 'when the partition contains executable jobs' do
        before do
          create(job_factory, :pending)
          create(job_factory, :running)
          create(job_factory, :succeeded)
        end

        it { is_expected.to be(false) }
      end

      context 'when the partition contains only non-executable jobs' do
        before do
          create(job_factory, :succeeded)
          create(job_factory, :failed)
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

        # it's not a day old yet so no new partitions are created
        partition_manager.sync_partitions

        expect(described_class.partitioning_strategy.current_partitions.map(&:value)).to match_array([1])

        # add one record so the next partition will be created
        create(job_factory) # rubocop:disable Rails/SaveBang -- factory

        # after traveling forward past PARTITION_DURATION
        travel(Gitlab::Database::BackgroundOperation::Worker::PARTITION_DURATION + 1.second)

        # a new partition is created
        partition_manager.sync_partitions

        expect(described_class.partitioning_strategy.current_partitions.map(&:value)).to match_array([1, 2])

        # and we can insert to the new partition
        expect { create(job_factory) }.not_to raise_error # rubocop:disable Rails/SaveBang -- factory

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
