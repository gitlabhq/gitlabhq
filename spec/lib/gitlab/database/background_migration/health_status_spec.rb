# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::BackgroundMigration::HealthStatus, feature_category: :database do
  let(:connection) { Gitlab::Database.database_base_models[:main].connection }

  around do |example|
    Gitlab::Database::SharedModel.using_connection(connection) do
      example.run
    end
  end

  describe '.evaluate' do
    subject(:evaluate) { described_class.evaluate(migration, [autovacuum_indicator_class]) }

    let(:migration) { build(:batched_background_migration, :active) }

    let(:health_status) { Gitlab::Database::BackgroundMigration::HealthStatus }
    let(:autovacuum_indicator_class) { health_status::Indicators::AutovacuumActiveOnTable }
    let(:wal_indicator_class) { health_status::Indicators::WriteAheadLog }
    let(:patroni_apdex_indicator_class) { health_status::Indicators::PatroniApdex }
    let(:autovacuum_indicator) { instance_double(autovacuum_indicator_class) }
    let(:wal_indicator) { instance_double(wal_indicator_class) }
    let(:patroni_apdex_indicator) { instance_double(patroni_apdex_indicator_class) }

    before do
      allow(autovacuum_indicator_class).to receive(:new).with(migration.health_context).and_return(autovacuum_indicator)
    end

    context 'with default indicators' do
      subject(:evaluate) { described_class.evaluate(migration) }

      it 'returns a collection of signals' do
        normal_signal = instance_double("#{health_status}::Signals::Normal", log_info?: false)
        not_available_signal = instance_double("#{health_status}::Signals::NotAvailable", log_info?: false)

        expect(autovacuum_indicator).to receive(:evaluate).and_return(normal_signal)
        expect(wal_indicator_class).to receive(:new).with(migration.health_context).and_return(wal_indicator)
        expect(wal_indicator).to receive(:evaluate).and_return(not_available_signal)
        expect(patroni_apdex_indicator_class).to receive(:new).with(migration.health_context)
          .and_return(patroni_apdex_indicator)
        expect(patroni_apdex_indicator).to receive(:evaluate).and_return(not_available_signal)

        expect(evaluate).to contain_exactly(normal_signal, not_available_signal, not_available_signal)
      end
    end

    it 'returns a collection of signals' do
      signal = instance_double("#{health_status}::Signals::Normal", log_info?: false)

      expect(autovacuum_indicator).to receive(:evaluate).and_return(signal)

      expect(evaluate).to contain_exactly(signal)
    end

    it 'logs interesting signals' do
      signal = instance_double(
        "#{health_status}::Signals::Stop",
        log_info?: true,
        indicator_class: autovacuum_indicator_class,
        short_name: 'Stop',
        reason: 'Test Exception'
      )

      expect(autovacuum_indicator).to receive(:evaluate).and_return(signal)

      expect(Gitlab::BackgroundMigration::Logger).to receive(:info).with(
        migration_id: migration.id,
        health_status_indicator: autovacuum_indicator_class.to_s,
        indicator_signal: 'Stop',
        signal_reason: 'Test Exception',
        message: "#{migration} signaled: #{signal}"
      )

      evaluate
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
        expect(autovacuum_indicator).to receive(:evaluate).and_raise(error)
      end

      it 'does not fail' do
        expect { evaluate }.not_to raise_error
      end

      it 'returns Unknown signal' do
        signal = evaluate.first

        expect(signal).to be_an_instance_of(Gitlab::Database::BackgroundMigration::HealthStatus::Signals::Unknown)
        expect(signal.reason).to eq("unexpected error: everything broken (RuntimeError)")
      end

      it 'reports the exception to error tracking' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception)
          .with(error, migration_id: migration.id, job_class_name: migration.job_class_name)

        evaluate
      end
    end
  end
end
