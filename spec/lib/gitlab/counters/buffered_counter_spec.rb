# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Counters::BufferedCounter, :clean_gitlab_redis_shared_state, feature_category: :groups_and_projects do
  using RSpec::Parameterized::TableSyntax

  subject(:counter) { described_class.new(counter_record, attribute) }

  let_it_be(:counter_record) { create(:project_statistics) }

  let(:attribute) { :build_artifacts_size }

  describe '#get' do
    it 'returns the value when there is an existing value stored in the counter' do
      Gitlab::Redis::BufferedCounter.with do |redis|
        redis.set(counter.key, 456)
      end

      expect(counter.get).to eq(456)
    end

    it 'returns 0 when there is no existing value' do
      expect(counter.get).to eq(0)
    end
  end

  describe '#increment' do
    let(:increment) { Gitlab::Counters::Increment.new(amount: 123, ref: 1) }
    let(:other_increment) { Gitlab::Counters::Increment.new(amount: 100, ref: 2) }

    context 'when the counter is not undergoing refresh' do
      it 'sets a new key by the given value' do
        counter.increment(increment)

        expect(counter.get).to eq(increment.amount)
      end

      it 'increments an existing key by the given value' do
        counter.increment(other_increment)
        counter.increment(increment)

        expect(counter.get).to eq(other_increment.amount + increment.amount)
      end

      it 'returns the value of the key after the increment' do
        counter.increment(increment)
        result = counter.increment(other_increment)

        expect(result).to eq(increment.amount + other_increment.amount)
      end

      it 'schedules a worker to commit the counter key into database' do
        expect(FlushCounterIncrementsWorker).to receive(:perform_in)
          .with(described_class::WORKER_DELAY, counter_record.class.to_s, counter_record.id, attribute.to_s)

        counter.increment(increment)
      end
    end

    context 'when the counter is undergoing refresh' do
      let(:increment_1) { Gitlab::Counters::Increment.new(amount: 123, ref: 1) }
      let(:decrement_1) { Gitlab::Counters::Increment.new(amount: -increment_1.amount, ref: increment_1.ref) }

      let(:increment_2) { Gitlab::Counters::Increment.new(amount: 100, ref: 2) }
      let(:decrement_2) { Gitlab::Counters::Increment.new(amount: -increment_2.amount, ref: increment_2.ref) }

      before do
        counter.initiate_refresh!
      end

      it 'does not increment the counter key' do
        expect { counter.increment(increment) }.not_to change { counter.get }.from(0)
      end

      it 'increments the amount in the refresh key' do
        counter.increment(increment)

        expect(redis_get_key(counter.refresh_key).to_i).to eq(increment.amount)
      end

      it 'schedules a worker to commit the counter key into database' do
        expect(FlushCounterIncrementsWorker).to receive(:perform_in)
          .with(described_class::WORKER_DELAY, counter_record.class.to_s, counter_record.id, attribute.to_s)

        counter.increment(increment)
      end

      shared_examples 'changing the counter refresh key by the given amount' do
        it 'changes the refresh counter key by the given value' do
          expect { counter.increment(increment) }
            .to change { redis_get_key(counter.refresh_key).to_i }.by(increment.amount)
        end

        it 'returns the value of the key after the increment' do
          expect(counter.increment(increment)).to eq(expected_counter_value)
        end
      end

      shared_examples 'not changing the counter refresh key' do
        it 'does not change the counter' do
          expect { counter.increment(increment) }.not_to change { redis_get_key(counter.refresh_key).to_i }
        end

        it 'returns the unchanged value of the key' do
          expect(counter.increment(increment)).to eq(expected_counter_value)
        end
      end

      context 'when it is an increment (positive amount)' do
        let(:increment) { increment_1 }

        context 'when it is the first increment on the ref' do
          let(:expected_counter_value) { increment.amount }

          it_behaves_like 'changing the counter refresh key by the given amount'
        end

        context 'when it follows an existing increment on the same ref' do
          before do
            counter.increment(increment)
          end

          let(:expected_counter_value) { increment.amount }

          it_behaves_like 'not changing the counter refresh key'
        end

        context 'when it follows an existing decrement on the same ref' do
          before do
            counter.increment(decrement_1)
          end

          let(:expected_counter_value) { 0 }

          it_behaves_like 'not changing the counter refresh key'
        end

        context 'when there has been an existing increment on another ref' do
          before do
            counter.increment(increment_2)
          end

          let(:expected_counter_value) { increment.amount + increment_2.amount }

          it_behaves_like 'changing the counter refresh key by the given amount'
        end

        context 'when there has been an existing decrement on another ref' do
          before do
            counter.increment(decrement_2)
          end

          let(:expected_counter_value) { increment.amount }

          it_behaves_like 'changing the counter refresh key by the given amount'
        end
      end

      context 'when it is a decrement (negative amount)' do
        let(:increment) { decrement_1 }

        context 'when it is the first decrement on the same ref' do
          let(:expected_counter_value) { 0 }

          it_behaves_like 'not changing the counter refresh key'
        end

        context 'when it follows an existing decrement on the ref' do
          before do
            counter.increment(decrement_1)
          end

          let(:expected_counter_value) { 0 }

          it_behaves_like 'not changing the counter refresh key'
        end

        context 'when it follows an existing increment on the ref' do
          before do
            counter.increment(increment_1)
          end

          let(:expected_counter_value) { 0 }

          it_behaves_like 'changing the counter refresh key by the given amount'
        end

        context 'when there has been an existing increment on another ref' do
          before do
            counter.increment(increment_2)
          end

          let(:expected_counter_value) { increment_2.amount }

          it_behaves_like 'not changing the counter refresh key'
        end

        context 'when there has been an existing decrement on another ref' do
          before do
            counter.increment(decrement_2)
          end

          let(:expected_counter_value) { 0 }

          it_behaves_like 'not changing the counter refresh key'
        end
      end

      context 'when the amount is 0' do
        let(:increment) { Gitlab::Counters::Increment.new(amount: 0, ref: 1) }

        context 'when it is the first increment on the ref' do
          let(:expected_counter_value) { 0 }

          it_behaves_like 'not changing the counter refresh key'
        end

        context 'when it follows the another increment on the ref' do
          let(:expected_counter_value) { 0 }

          before do
            counter.increment(increment)
          end

          it_behaves_like 'not changing the counter refresh key'
        end
      end

      context 'when the ref is greater than 67108863 (8MB)' do
        let(:increment) { Gitlab::Counters::Increment.new(amount: 123, ref: 67108864) }

        let(:increment_2) { Gitlab::Counters::Increment.new(amount: 123, ref: 267108863) }
        let(:decrement_2) { Gitlab::Counters::Increment.new(amount: -increment_2.amount, ref: increment_2.ref) }

        let(:expected_counter_value) { increment.amount }

        it 'deduplicates increments correctly' do
          counter.increment(decrement_2)
          counter.increment(increment)
          counter.increment(increment_2)

          expect(redis_get_key(counter.refresh_key).to_i).to eq(increment.amount)
        end
      end
    end
  end

  describe '#bulk_increment' do
    let(:other_increment) { Gitlab::Counters::Increment.new(amount: 1) }
    let(:increments) { [Gitlab::Counters::Increment.new(amount: 123), Gitlab::Counters::Increment.new(amount: 456)] }

    context 'when the counter is not undergoing refresh' do
      it 'increments the key by the given values' do
        counter.bulk_increment(increments)

        expect(counter.get).to eq(increments.sum(&:amount))
      end

      it 'returns the value of the key after the increment' do
        counter.increment(other_increment)

        result = counter.bulk_increment(increments)

        expect(result).to eq(other_increment.amount + increments.sum(&:amount))
      end

      it 'schedules a worker to commit the counter into database' do
        expect(FlushCounterIncrementsWorker).to receive(:perform_in)
          .with(described_class::WORKER_DELAY, counter_record.class.to_s, counter_record.id, attribute.to_s)

        counter.bulk_increment(increments)
      end
    end

    context 'when the counter is undergoing refresh' do
      let(:increment_1) { Gitlab::Counters::Increment.new(amount: 123, ref: 1) }
      let(:decrement_1) { Gitlab::Counters::Increment.new(amount: -increment_1.amount, ref: increment_1.ref) }

      let(:increment_2) { Gitlab::Counters::Increment.new(amount: 100, ref: 2) }
      let(:decrement_2) { Gitlab::Counters::Increment.new(amount: -increment_2.amount, ref: increment_2.ref) }

      let(:increment_3) { Gitlab::Counters::Increment.new(amount: 100, ref: 3) }
      let(:decrement_3) { Gitlab::Counters::Increment.new(amount: -increment_3.amount, ref: increment_3.ref) }

      before do
        counter.initiate_refresh!
      end

      shared_examples 'changing the counter refresh key by the expected amount' do
        it 'changes the counter refresh key by the net change' do
          expect { counter.bulk_increment(increments) }
            .to change { redis_get_key(counter.refresh_key).to_i }.by(expected_change)
        end

        it 'returns the value of the key after the increment' do
          expect(counter.bulk_increment(increments)).to eq(expected_counter_value)
        end
      end

      context 'when there are 2 increments on different ref' do
        let(:increments) { [increment_1, increment_2] }
        let(:expected_change) { increments.sum(&:amount) }
        let(:expected_counter_value) { increments.sum(&:amount) }

        it_behaves_like 'changing the counter refresh key by the expected amount'

        context 'when there has been previous decrements' do
          before do
            counter.increment(decrement_1)
            counter.increment(decrement_3)
          end

          let(:expected_change) { increment_2.amount }
          let(:expected_counter_value) { increment_2.amount }

          it_behaves_like 'changing the counter refresh key by the expected amount'
        end

        context 'when one of the increment is repeated' do
          before do
            counter.increment(increment_2)
          end

          let(:expected_change) { increment_1.amount }
          let(:expected_counter_value) { increment_2.amount + increment_1.amount }

          it_behaves_like 'changing the counter refresh key by the expected amount'
        end
      end

      context 'when there are 2 decrements on different ref' do
        let(:increments) { [decrement_1, decrement_2] }
        let(:expected_change) { 0 }
        let(:expected_counter_value) { 0 }

        it_behaves_like 'changing the counter refresh key by the expected amount'

        context 'when there has been previous increments' do
          before do
            counter.increment(increment_1)
            counter.increment(increment_3)
          end

          let(:expected_change) { decrement_1.amount }
          let(:expected_counter_value) { increment_3.amount }

          it_behaves_like 'changing the counter refresh key by the expected amount'
        end
      end

      context 'when there is a mixture of increment and decrement on different refs' do
        let(:increments) { [increment_1, decrement_2] }
        let(:expected_change) { increment_1.amount }
        let(:expected_counter_value) { increment_1.amount }

        it_behaves_like 'changing the counter refresh key by the expected amount'

        context 'when the increment ref has been decremented' do
          before do
            counter.increment(decrement_1)
          end

          let(:expected_change) { 0 }
          let(:expected_counter_value) { 0 }

          it_behaves_like 'changing the counter refresh key by the expected amount'
        end

        context 'when the decrement ref has been incremented' do
          before do
            counter.increment(increment_2)
          end

          let(:expected_change) { increments.sum(&:amount) }
          let(:expected_counter_value) { increment_1.amount }

          it_behaves_like 'changing the counter refresh key by the expected amount'
        end
      end
    end
  end

  describe '#initiate_refresh!' do
    let(:increment) { Gitlab::Counters::Increment.new(amount: 123) }

    before do
      allow(counter_record).to receive(:update!)

      counter.increment(increment)
    end

    it 'removes the key from Redis' do
      counter.initiate_refresh!

      Gitlab::Redis::BufferedCounter.with do |redis|
        expect(redis.exists?(counter.key)).to eq(false)
      end
    end

    it 'resets the counter to 0' do
      counter.initiate_refresh!

      expect(counter.get).to eq(0)
    end

    it 'resets the record to 0' do
      expect(counter_record).to receive(:update!).with(attribute => 0)

      counter.initiate_refresh!
    end

    it 'sets a refresh indicator with a long expiry' do
      counter.initiate_refresh!

      expect(redis_exists_key(counter.refresh_indicator_key)).to eq(true)
      expect(redis_key_ttl(counter.refresh_indicator_key)).to eq(described_class::REFRESH_KEYS_TTL)
    end
  end

  describe '#finalize_refresh' do
    before do
      counter.initiate_refresh!
    end

    context 'with existing amount in refresh key' do
      let(:increment) { Gitlab::Counters::Increment.new(amount: 123, ref: 1) }
      let(:other_increment) { Gitlab::Counters::Increment.new(amount: 100, ref: 2) }
      let(:other_decrement) { Gitlab::Counters::Increment.new(amount: -100, ref: 2) }

      before do
        counter.bulk_increment([other_decrement, increment, other_increment])
      end

      it 'moves the deduplicated amount in the refresh key into the counter key' do
        expect { counter.finalize_refresh }
          .to change { counter.get }.by(increment.amount)
      end

      it 'removes the refresh counter key and the refresh indicator' do
        expect { counter.finalize_refresh }
          .to change { redis_exists_key(counter.refresh_key) }.from(true).to(false)
          .and change { redis_exists_key(counter.refresh_indicator_key) }.from(true).to(false)
      end

      it 'schedules a worker to clean up the refresh tracking keys' do
        expect(Counters::CleanupRefreshWorker).to receive(:perform_async)
          .with(counter_record.class.to_s, counter_record.id, attribute)

        counter.finalize_refresh
      end
    end

    context 'without existing amount in refresh key' do
      it 'does not change the counter key' do
        expect { counter.finalize_refresh }.not_to change { counter.get }
      end

      it 'removes the refresh indicator key' do
        expect { counter.finalize_refresh }
          .to change { redis_exists_key(counter.refresh_indicator_key) }.from(true).to(false)
      end

      it 'schedules a worker to commit the counter key into database' do
        expect(FlushCounterIncrementsWorker).to receive(:perform_in)
          .with(described_class::WORKER_DELAY, counter_record.class.to_s, counter_record.id, attribute.to_s)

        counter.finalize_refresh
      end
    end
  end

  describe '#cleanup_refresh' do
    let(:increment) { Gitlab::Counters::Increment.new(amount: 123, ref: 67108864) }
    let(:increment_2) { Gitlab::Counters::Increment.new(amount: 123, ref: 267108864) }
    let(:decrement_2) { Gitlab::Counters::Increment.new(amount: -increment_2.amount, ref: increment_2.ref) }
    let(:increment_3) { Gitlab::Counters::Increment.new(amount: 123, ref: 534217728) }

    before do
      stub_const("#{described_class}::CLEANUP_BATCH_SIZE", 2)
      stub_const("#{described_class}::CLEANUP_INTERVAL_SECONDS", 0.001)

      counter.initiate_refresh!
      counter.increment(decrement_2)
      counter.increment(increment)
      counter.increment(increment_2)
      counter.finalize_refresh
    end

    it 'removes all tracking keys' do
      Gitlab::Redis::BufferedCounter.with do |redis|
        expect { counter.cleanup_refresh }
          .to change { redis.scan_each(match: "#{counter.refresh_key}*").to_a.count }.from(4).to(0)
      end
    end
  end

  describe '#commit_increment!' do
    it 'obtains an exclusive lease during processing' do
      expect(counter).to receive(:with_exclusive_lease).and_call_original

      counter.commit_increment!
    end

    context 'when there is an amount to commit' do
      let(:increments) { [10, -3].map { |amt| Gitlab::Counters::Increment.new(amount: amt) } }

      before do
        increments.each { |i| counter.increment(i) }
      end

      it 'commits the increment into the database' do
        expect { counter.commit_increment! }
          .to change { counter_record.reset.read_attribute(attribute) }.by(increments.sum(&:amount))
      end

      it 'removes the increment entry from Redis' do
        expect { counter.commit_increment! }.to change { redis_exists_key(counter.key) }.from(true).to(false)
      end
    end

    context 'when there are no counters to flush' do
      context 'when there are no counters in the relative :flushed key' do
        it 'does not change the record' do
          expect { counter.commit_increment! }.not_to change { counter_record.reset.attributes }
        end
      end

      # This can be the case where updating counters in the database fails with error
      # and retrying the worker will retry flushing the counters but the main key has
      # disappeared and the increment has been moved to the "<...>:flushed" key.
      context 'when there are counters in the relative :flushed key' do
        let(:flushed_amount) { 10 }

        before do
          Gitlab::Redis::BufferedCounter.with do |redis|
            redis.incrby(counter.flushed_key, flushed_amount)
          end
        end

        it 'updates the record' do
          expect { counter.commit_increment! }
            .to change { counter_record.reset.read_attribute(attribute) }.by(flushed_amount)
        end

        it 'deletes the relative :flushed key' do
          counter.commit_increment!

          Gitlab::Redis::BufferedCounter.with do |redis|
            key_exists = redis.exists?(counter.flushed_key)
            expect(key_exists).to be_falsey
          end
        end
      end

      context 'when deleting :flushed key fails' do
        before do
          Gitlab::Redis::BufferedCounter.with do |redis|
            redis.incrby(counter.flushed_key, 10)

            allow(redis).to receive(:del).and_raise('could not delete key')
          end
        end

        it 'does a rollback of the counter update' do
          expect { counter.commit_increment! }.to raise_error('could not delete key')

          expect(counter_record.reset.read_attribute(attribute)).to eq(0)
        end
      end

      context 'when the counter record has after_commit callbacks' do
        it 'has registered callbacks' do
          expect(counter_record.class.after_commit_callbacks.size).to eq(1)
        end

        context 'when there are increments to flush' do
          before do
            counter.increment(Gitlab::Counters::Increment.new(amount: 10))
          end

          it 'executes the callbacks' do
            expect(counter_record).to receive(:execute_after_commit_callbacks).and_call_original

            counter.commit_increment!
          end
        end

        context 'when there are no increments to flush' do
          it 'does not execute the callbacks' do
            expect(counter_record).not_to receive(:execute_after_commit_callbacks).and_call_original

            counter.commit_increment!
          end
        end
      end
    end
  end

  describe '#amount_to_be_flushed' do
    let(:increment_key) { counter.key }
    let(:flushed_key) { counter.flushed_key }

    where(:increment, :flushed, :result, :flushed_key_present) do
      nil | nil | 0  | false
      nil | 0   | 0  | false
      0   | 0   | 0  | false
      1   | 0   | 1  | true
      1   | nil | 1  | true
      1   | 1   | 2  | true
      1   | -2  | -1 | true
      -1  | 1   | 0  | false
    end

    with_them do
      before do
        Gitlab::Redis::BufferedCounter.with do |redis|
          redis.set(increment_key, increment) if increment
          redis.set(flushed_key, flushed) if flushed
        end
      end

      it 'returns the current value to be flushed' do
        value = counter.amount_to_be_flushed
        expect(value).to eq(result)
      end

      it 'drops the increment key and creates the flushed key if it does not exist' do
        counter.amount_to_be_flushed

        expect(redis_exists_key(increment_key)).to eq(false)
        expect(redis_exists_key(flushed_key)).to eq(flushed_key_present)
      end
    end
  end

  def redis_get_key(key)
    Gitlab::Redis::BufferedCounter.with do |redis|
      redis.get(key)
    end
  end

  def redis_exists_key(key)
    Gitlab::Redis::BufferedCounter.with do |redis|
      redis.exists?(key)
    end
  end

  def redis_key_ttl(key)
    Gitlab::Redis::BufferedCounter.with do |redis|
      redis.ttl(key)
    end
  end
end
