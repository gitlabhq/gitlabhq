# frozen_string_literal: true

RSpec.shared_examples 'background operation worker functionality' do |worker_factory, job_factory|
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

    let(:unfinished_workers) { [queued_worker, active_worker, paused_worker] }

    describe '.unfinished' do
      it 'returns workers with queued, active or paused status' do
        expect(described_class.unfinished).to match_array(unfinished_workers)
      end
    end

    describe '.unfinished_with_config' do
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

      it 'returns unfinished workers with the given configurations' do
        extra_param = if worker_factory == :background_operation_worker
                        { org_id: active_worker.organization_id }
                      else
                        {}
                      end

        expect(described_class.unfinished_with_config(*config.values, **extra_param))
          .to match_array([active_worker])
      end
    end

    describe '.executable' do
      let_it_be(:paused_without_hold) { create(worker_factory, :paused, on_hold_until: 2.days.ago) }

      it 'returns workers with queued, paused status and on_hold_until in the past' do
        expect(described_class.executable).to match_array([queued_worker, paused_without_hold])
      end
    end
  end

  describe '.schedulable_workers' do
    let(:partition_manager) { Gitlab::Database::Partitioning::PartitionManager.new(described_class) }

    it 'returns executable workers in asc order with the limit' do
      projects_worker_1 = create(worker_factory, :queued, table_name: 'projects')

      travel(described_class::PARTITION_DURATION + 1.minute)
      partition_manager.sync_partitions

      projects_worker_2 = create(worker_factory, :queued, table_name: 'projects')
      namespaces_worker_2 = create(worker_factory, :queued, table_name: 'namespaces')

      issues_worker_2 = create(
        worker_factory,
        :paused,
        table_name: 'issues',
        on_hold_until: (described_class::PARTITION_DURATION + 5.days).ago
      )

      # Won't be scheduled as its over the limit
      create(worker_factory, :active, table_name: 'users')

      expected_worker_ids = [projects_worker_1, projects_worker_2, namespaces_worker_2, issues_worker_2].map do |w|
        w.attributes['id']
      end

      expect(described_class.schedulable_workers(4).pluck(:id))
        .to match_array(expected_worker_ids)
    end
  end

  describe 'sliding_list partitioning' do
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

      context 'when the partition contains unfinished workers' do
        before do
          create(worker_factory, :active)
          create(worker_factory, :paused)
          create(worker_factory, :finished)
        end

        it { is_expected.to be(false) }
      end

      context 'when the partition contains only non-unfinished workers' do
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

        # after marking old records as non-unfinished
        described_class.for_partition(1).update_all(status: 3)

        partition_manager.sync_partitions

        # the old one is removed
        expect(described_class.partitioning_strategy.current_partitions.map(&:value)).to match_array([2])

        # and we only have the newly created partition left.
        expect(described_class.count).to eq(1)
      end
    end
  end

  describe '#should_stop?' do
    let(:worker) { create(worker_factory, :active, started_at: started_at) }

    subject(:should_stop?) { worker.should_stop? }

    before do
      stub_const('Gitlab::Database::BackgroundOperation::CommonWorker::MINIMUM_JOBS_FOR_FAILURE_CHECK', 1)
    end

    context 'when started_at is nil' do
      let(:started_at) { nil }

      it { expect(should_stop?).to be_falsey }
    end

    context 'when the number of jobs is less than MINIMUM_JOBS_FOR_FAILURE_CHECK' do
      let(:started_at) { 6.days.ago }

      before do
        stub_const('Gitlab::Database::BackgroundOperation::CommonWorker::MINIMUM_JOBS_FOR_FAILURE_CHECK', 10)
        create_list(job_factory, 1, :succeeded, worker: worker)
        create_list(job_factory, 3, :failed, worker: worker)
      end

      it { expect(should_stop?).to be_falsey }
    end

    context 'when the calculated value is greater than the threshold' do
      let(:started_at) { 6.days.ago }

      before do
        stub_const('Gitlab::Database::BackgroundOperation::CommonWorker::MAXIMUM_FAILURE_RATIO', 0.70)
        create_list(job_factory, 1, :succeeded, worker: worker)
        create_list(job_factory, 3, :failed, worker: worker)
      end

      it { expect(should_stop?).to be_truthy }
    end

    context 'when the calculated value is lesser than the threshold' do
      let(:started_at) { 6.days.ago }

      before do
        create_list(job_factory, 2, :succeeded, worker: worker)
      end

      it { expect(should_stop?).to be_falsey }
    end
  end

  describe '#on_hold?', :freeze_time do
    let_it_be(:worker) { create(worker_factory, :queued) }

    subject(:on_hold) { worker.on_hold? }

    context 'when on_hold_until is nil' do
      it { expect(on_hold).to be_falsey }
    end

    context 'when on_hold_until is set' do
      before do
        worker.update!(on_hold_until: on_hold_until)
      end

      context 'when the hold duration is in the past' do
        let(:on_hold_until) { 1.minute.ago }

        it { is_expected.to be_falsey }
      end

      context 'when the hold duration is in the future' do
        let(:on_hold_until) { 1.minute.from_now }

        it { is_expected.to be_truthy }
      end
    end
  end

  describe '.hold!', :freeze_time do
    subject(:worker) { create(worker_factory, :queued) }

    it 'defaults to 10 minutes' do
      expect { worker.hold! }.to change { worker.on_hold_until }.from(nil).to(10.minutes.from_now)
    end
  end

  describe '#optimize!' do
    subject(:optimize) { worker.optimize! }

    let(:batch_size) { 10_000 }
    let(:worker) { create(worker_factory, batch_size: batch_size) }

    it 'does not update batch_size when efficiency is nil' do
      expect { optimize }.not_to change { worker.reload.batch_size }
    end

    context 'when efficiency is low' do
      before do
        allow(worker).to receive(:smoothed_time_efficiency).and_return(0.7)
      end

      it 'updates batch_size' do
        # With efficiency 0.7: multiplier = 0.95/0.7 = 1.357, capped at 1.2
        # New size = 10,000 * 1.2 = 12,000
        expect { optimize }.to change { worker.reload.batch_size }.from(batch_size).to(12_000)
      end
    end

    context 'when efficiency is high' do
      before do
        allow(worker).to receive(:smoothed_time_efficiency).and_return(1.5)
      end

      it 'updates batch_size' do
        # With efficiency 1.5: multiplier = 0.95/1.5 = 0.633
        # New size = 10,000 * 0.633 = 6,333
        expect { optimize }.to change { worker.reload.batch_size }.from(batch_size).to(6_333)
      end
    end
  end
end
