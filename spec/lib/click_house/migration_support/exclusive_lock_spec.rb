# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClickHouse::MigrationSupport::ExclusiveLock, feature_category: :database do
  include ExclusiveLeaseHelpers

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
    before do
      TestWorker.click_house_migration_lock(10.seconds)
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
        described_class.register_running_worker(worker_class, anything) do
          example.run
        end
      end

      it 'waits for workers and raises ClickHouse::MigrationSupport::LockError if workers do not stop in time' do
        expect(described_class).to receive(:sleep).at_least(1).with(sleep_time) { travel(sleep_time) }

        expect { migration }.to raise_error(ClickHouse::MigrationSupport::Errors::LockError,
          /Timed out waiting for active workers/)
        expect(Time.current - started_at).to eq(described_class::DEFAULT_CLICKHOUSE_WORKER_TTL)
      end

      context 'when wait_for_clickhouse_workers_during_migration FF is disabled' do
        before do
          stub_feature_flags(wait_for_clickhouse_workers_during_migration: false)
        end

        it 'runs migration without waiting for workers' do
          expect { migration }.not_to raise_error
          expect(Time.current - started_at).to eq(0.0)
        end
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
end
