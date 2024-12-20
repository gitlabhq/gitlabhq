# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClickHouse::MigrationSupport::ExclusiveLock, feature_category: :database do
  include ExclusiveLeaseHelpers

  let(:worker_id) { 1 }

  let(:worker_class) do
    # This worker will be active longer than the ClickHouse worker TTL
    Class.new do
      def self.name
        'TestWorker'
      end

      include ::ApplicationWorker
      include ::ClickHouseWorker

      def perform(*); end
    end
  end

  before do
    stub_const('TestWorker', worker_class)
  end

  describe '.register_running_worker' do
    let(:worker_ttl) { 10.seconds }

    before do
      TestWorker.click_house_migration_lock(worker_ttl)
    end

    it 'yields without arguments' do
      expect { |b| described_class.register_running_worker(worker_class, 'test', &b) }.to yield_with_no_args
    end

    it 'registers worker for a limited period of time', :freeze_time, :aggregate_failures do
      expect(described_class.active_sidekiq_workers?).to eq false

      described_class.register_running_worker(worker_class, 'test') do
        expect(described_class.active_sidekiq_workers?).to eq true
        travel 9.seconds
        expect(described_class.active_sidekiq_workers?).to eq true
        travel 2.seconds
        expect(described_class.active_sidekiq_workers?).to eq false
      end
    end

    it 'is compatible with Redis 6.0' do
      redis_mock = instance_double(Redis)
      expect(redis_mock).to receive(:zscore).and_return(1)
      allow(redis_mock).to receive(:zadd)
      expect(redis_mock).to receive(:zrem)
      expect(Gitlab::Redis::SharedState).to receive(:with).and_yield(redis_mock)

      described_class.register_running_worker(worker_class, 'test') do
        next
      end

      # Ensure gt: true parameter is not passed
      expect(redis_mock).to have_received(:zadd).with(
        described_class::ACTIVE_WORKERS_REDIS_KEY,
        worker_ttl.from_now.to_i,
        'test'
      )
    end

    context 'when scheduling the same worker concurrently', :freeze_time, :aggregate_failures do
      let(:worker_name) { 'test' }

      def get_ttl
        Gitlab::Redis::SharedState.with do |redis|
          redis.zrange(described_class::ACTIVE_WORKERS_REDIS_KEY, 0, -1, with_scores: true)[0][1]
        end
      end

      context 'when ttl is in the future' do
        it 'updates worker ttl' do
          described_class.register_running_worker(worker_class, worker_name) do
            old_ttl = get_ttl
            expect(old_ttl).to eq((Time.current + worker_ttl).to_i)

            travel 1.second

            described_class.register_running_worker(worker_class, worker_name) do
              new_ttl = get_ttl
              expect(new_ttl).to be > old_ttl
            end
          end
        end
      end

      context 'when ttl is in the past' do
        it 'does not update worker ttl' do
          described_class.register_running_worker(worker_class, worker_name) do
            old_ttl = get_ttl
            expect(old_ttl).to eq(worker_ttl.from_now.to_i)

            travel_to 1.second.ago

            described_class.register_running_worker(worker_class, worker_name) do
              new_ttl = get_ttl
              expect(new_ttl).to eq(old_ttl)
            end
          end
        end
      end
    end
  end

  describe '.pause_workers?' do
    subject(:pause_workers?) { described_class.pause_workers? }

    it { is_expected.to eq false }

    context 'with lock taken' do
      let!(:lease) { stub_exclusive_lease_taken(described_class::MIGRATION_LEASE_KEY) }

      it { is_expected.to eq true }
    end
  end

  describe '.execute_migration' do
    it 'yields without raising error' do
      expect { |b| described_class.execute_migration(&b) }.to yield_with_no_args
    end

    context 'when migration lock is taken' do
      let!(:lease) { stub_exclusive_lease_taken(described_class::MIGRATION_LEASE_KEY) }

      it 'raises LockError' do
        expect do
          expect { |b| described_class.execute_migration(&b) }.not_to yield_control
        end.to raise_error ::ClickHouse::MigrationSupport::Errors::LockError
      end
    end

    context 'when ClickHouse workers are still active', :freeze_time do
      let(:sleep_time) { described_class::WORKERS_WAIT_SLEEP }
      let!(:started_at) { Time.current }

      def migration
        expect { |b| described_class.execute_migration(&b) }.to yield_with_no_args
      end

      around do |example|
        described_class.register_running_worker(worker_class, worker_id) do
          example.run
        end
      end

      it 'waits for workers and raises ClickHouse::MigrationSupport::LockError if workers do not stop in time' do
        expect(described_class).to receive(:sleep).at_least(1).with(sleep_time) { travel(sleep_time) }

        expect { migration }.to raise_error(ClickHouse::MigrationSupport::Errors::LockError,
          /Timed out waiting for active workers/)
        expect(Time.current - started_at).to eq(described_class::DEFAULT_CLICKHOUSE_WORKER_TTL)
      end

      it 'ignores expired workers' do
        travel(described_class::DEFAULT_CLICKHOUSE_WORKER_TTL + 1.second)

        migration
      end

      context 'when worker registration is almost expiring' do
        let(:worker_class) do
          # This worker will be active for less than the ClickHouse worker TTL
          Class.new do
            def self.name
              'TestWorker'
            end

            include ::ApplicationWorker
            include ::ClickHouseWorker

            click_house_migration_lock(
              ClickHouse::MigrationSupport::ExclusiveLock::DEFAULT_CLICKHOUSE_WORKER_TTL - 1.second)

            def perform(*); end
          end
        end

        it 'completes migration' do
          expect(described_class).to receive(:sleep).at_least(1).with(sleep_time) { travel(sleep_time) }

          expect { migration }.not_to raise_error
        end
      end
    end
  end

  describe '.active_sidekiq_workers?' do
    subject(:active_sidekiq_workers) { described_class.active_sidekiq_workers? }

    it 'returns false when no workers are registered' do
      is_expected.to eq false
    end

    it 'returns true when workers are registered' do
      described_class.register_running_worker(worker_class, 'test') do
        is_expected.to eq true
      end
    end

    it 'is compatible with Redis 6.0' do
      redis_mock = instance_double(Redis)
      allow(redis_mock).to receive_messages(zremrangebyscore: 1, zrangebyscore: [])
      allow(Gitlab::Redis::SharedState).to receive(:with).and_yield(redis_mock)

      expect(redis_mock).to receive(:zrangebyscore)
      expect(redis_mock).not_to receive(:zrange) # Not compatible with Redis 6

      active_sidekiq_workers
    end
  end
end
