# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::HealthStatus, feature_category: :database do
  let(:connection) { Gitlab::Database.database_base_models[:main].connection }

  around do |example|
    Gitlab::Database::SharedModel.using_connection(connection) do
      example.run
    end
  end

  describe '.evaluate' do
    subject(:evaluate) { described_class.evaluate(health_context, [autovacuum_indicator_class]) }

    let(:migration) { build(:batched_background_migration, :active) }
    let(:health_context) { migration.health_context }

    let(:health_status) { described_class }
    let(:autovacuum_indicator_class) { health_status::Indicators::AutovacuumActiveOnTable }
    let(:wal_indicator_class) { health_status::Indicators::WriteAheadLog }
    let(:patroni_apdex_indicator_class) { health_status::Indicators::PatroniApdex }
    let(:wal_rate_indicator_class) { health_status::Indicators::WalRate }
    let(:autovacuum_indicator) { instance_double(autovacuum_indicator_class) }
    let(:wal_indicator) { instance_double(wal_indicator_class) }
    let(:patroni_apdex_indicator) { instance_double(patroni_apdex_indicator_class) }
    let(:wal_rate_indicator) { instance_double(wal_rate_indicator_class) }

    before do
      allow(autovacuum_indicator_class).to receive(:new).with(health_context).and_return(autovacuum_indicator)
    end

    context 'with default indicators' do
      subject(:evaluate) { described_class.evaluate(health_context) }

      it 'returns a collection of signals' do
        normal_signal = instance_double("#{health_status}::Signals::Normal", log_info?: false)
        not_available_signal = instance_double("#{health_status}::Signals::NotAvailable", log_info?: false)

        expect(autovacuum_indicator).to receive(:evaluate).and_return(normal_signal)
        expect(wal_indicator_class).to receive(:new).with(health_context).and_return(wal_indicator)
        expect(wal_indicator).to receive(:evaluate).and_return(not_available_signal)
        expect(patroni_apdex_indicator_class).to receive(:new).with(health_context).and_return(patroni_apdex_indicator)
        expect(patroni_apdex_indicator).to receive(:evaluate).and_return(not_available_signal)
        expect(wal_rate_indicator_class).to receive(:new).with(health_context).and_return(wal_rate_indicator)
        expect(wal_rate_indicator).to receive(:evaluate).and_return(not_available_signal)

        expect(evaluate).to contain_exactly(
          normal_signal,
          not_available_signal,
          not_available_signal,
          not_available_signal
        )
      end
    end

    it 'returns the signal of the given indicator' do
      signal = instance_double("#{health_status}::Signals::Normal", log_info?: false)

      expect(autovacuum_indicator).to receive(:evaluate).and_return(signal)

      expect(evaluate).to contain_exactly(signal)
    end

    context 'with stop signals' do
      let(:stop_signal) do
        instance_double(
          "#{health_status}::Signals::Stop",
          log_info?: true,
          indicator_class: autovacuum_indicator_class,
          short_name: 'Stop',
          reason: 'Test Exception'
        )
      end

      before do
        allow(autovacuum_indicator).to receive(:evaluate).and_return(stop_signal)
      end

      context 'with batched migrations as the status checker' do
        it 'captures BatchedMigration class name in the log' do
          expect(Gitlab::Database::HealthStatus::Logger).to receive(:info).with(
            status_checker_id: migration.id,
            status_checker_type: 'Gitlab::Database::BackgroundMigration::BatchedMigration',
            job_class_name: migration.job_class_name,
            health_status_indicator: autovacuum_indicator_class.to_s,
            indicator_signal: 'Stop',
            signal_reason: 'Test Exception',
            message: "#{migration} signaled: #{stop_signal}"
          )

          evaluate
        end
      end

      context 'with sidekiq deferred job as the status checker' do
        let(:deferred_worker) do
          Class.new do
            def self.name
              'TestDeferredWorker'
            end

            include ApplicationWorker
          end
        end

        let(:deferred_worker_health_checker) do
          Gitlab::SidekiqMiddleware::SkipJobs::DatabaseHealthStatusChecker.new(
            123,
            deferred_worker.name
          )
        end

        let(:health_context) do
          Gitlab::Database::HealthStatus::Context.new(
            deferred_worker_health_checker,
            ActiveRecord::Base.connection,
            [:users]
          )
        end

        it 'captures sidekiq job class in the log' do
          expect(Gitlab::Database::HealthStatus::Logger).to receive(:info).with(
            status_checker_id: deferred_worker_health_checker.id,
            status_checker_type: 'Gitlab::SidekiqMiddleware::SkipJobs::DatabaseHealthStatusChecker',
            job_class_name: deferred_worker_health_checker.job_class_name,
            health_status_indicator: autovacuum_indicator_class.to_s,
            indicator_signal: 'Stop',
            signal_reason: 'Test Exception',
            message: "#{deferred_worker_health_checker} signaled: #{stop_signal}"
          )

          evaluate
        end
      end
    end

    it 'does not log signals of no interest' do
      signal = instance_double("#{health_status}::Signals::Normal", log_info?: false)

      expect(autovacuum_indicator).to receive(:evaluate).and_return(signal)
      expect(described_class).not_to receive(:log_signal)

      evaluate
    end

    context 'on indicator error' do
      let(:error) { RuntimeError.new('everything broken') }

      before do
        allow(autovacuum_indicator).to receive(:evaluate).and_raise(error)
      end

      it 'does not fail' do
        expect { evaluate }.not_to raise_error
      end

      it 'returns Unknown signal' do
        signal = evaluate.first

        expect(signal).to be_an_instance_of(Gitlab::Database::HealthStatus::Signals::Unknown)
        expect(signal.reason).to eq("unexpected error: everything broken (RuntimeError)")
      end

      it 'reports the exception to error tracking' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception)
          .with(
            error,
            status_checker_id: migration.id,
            status_checker_type: 'Gitlab::Database::BackgroundMigration::BatchedMigration',
            job_class_name: migration.job_class_name
          )

        evaluate
      end
    end
  end
end
