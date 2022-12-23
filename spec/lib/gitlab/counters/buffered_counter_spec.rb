# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Counters::BufferedCounter, :clean_gitlab_redis_shared_state do
  using RSpec::Parameterized::TableSyntax

  subject(:counter) { described_class.new(counter_record, attribute) }

  let_it_be(:counter_record) { create(:project_statistics) }
  let(:attribute) { :build_artifacts_size }

  describe '#get' do
    it 'returns the value when there is an existing value stored in the counter' do
      Gitlab::Redis::SharedState.with do |redis|
        redis.set(counter.key, 456)
      end

      expect(counter.get).to eq(456)
    end

    it 'returns 0 when there is no existing value' do
      expect(counter.get).to eq(0)
    end
  end

  describe '#increment' do
    let(:increment) { Gitlab::Counters::Increment.new(amount: 123) }
    let(:other_increment) { Gitlab::Counters::Increment.new(amount: 100) }

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

    it 'schedules a worker to commit the counter into database' do
      expect(FlushCounterIncrementsWorker).to receive(:perform_in)
        .with(described_class::WORKER_DELAY, counter_record.class.to_s, counter_record.id, attribute)

      counter.increment(increment)
    end
  end

  describe '#bulk_increment' do
    let(:other_increment) { Gitlab::Counters::Increment.new(amount: 1) }
    let(:increments) { [Gitlab::Counters::Increment.new(amount: 123), Gitlab::Counters::Increment.new(amount: 456)] }

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
        .with(described_class::WORKER_DELAY, counter_record.class.to_s, counter_record.id, attribute)

      counter.bulk_increment(increments)
    end
  end

  describe '#reset!' do
    let(:increment) { Gitlab::Counters::Increment.new(amount: 123) }

    before do
      allow(counter_record).to receive(:update!)

      counter.increment(increment)
    end

    it 'removes the key from Redis' do
      counter.reset!

      Gitlab::Redis::SharedState.with do |redis|
        expect(redis.exists?(counter.key)).to eq(false)
      end
    end

    it 'resets the counter to 0' do
      counter.reset!

      expect(counter.get).to eq(0)
    end

    it 'resets the record to 0' do
      expect(counter_record).to receive(:update!).with(attribute => 0)

      counter.reset!
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
        Gitlab::Redis::SharedState.with do |redis|
          key_exists = redis.exists?(counter.key)
          expect(key_exists).to be_truthy
        end

        counter.commit_increment!

        Gitlab::Redis::SharedState.with do |redis|
          key_exists = redis.exists?(counter.key)
          expect(key_exists).to be_falsey
        end
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
          Gitlab::Redis::SharedState.with do |redis|
            redis.incrby(counter.flushed_key, flushed_amount)
          end
        end

        it 'updates the record' do
          expect { counter.commit_increment! }
            .to change { counter_record.reset.read_attribute(attribute) }.by(flushed_amount)
        end

        it 'deletes the relative :flushed key' do
          counter.commit_increment!

          Gitlab::Redis::SharedState.with do |redis|
            key_exists = redis.exists?(counter.flushed_key)
            expect(key_exists).to be_falsey
          end
        end
      end

      context 'when deleting :flushed key fails' do
        before do
          Gitlab::Redis::SharedState.with do |redis|
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
        Gitlab::Redis::SharedState.with do |redis|
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

        Gitlab::Redis::SharedState.with do |redis|
          expect(redis.exists?(increment_key)).to eq(false)
          expect(redis.exists?(flushed_key)).to eq(flushed_key_present)
        end
      end
    end
  end
end
