# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::HealthStatus::Indicators::WriteAheadLog, feature_category: :database do
  let(:connection) { Gitlab::Database.database_base_models[:main].connection }

  around do |example|
    Gitlab::Database::SharedModel.using_connection(connection) do
      example.run
    end
  end

  describe '#evaluate' do
    let(:tables) { [table] }
    let(:table) { 'users' }
    let(:context) do
      Gitlab::Database::HealthStatus::Context.new(
        described_class,
        connection,
        tables
      )
    end

    subject(:evaluate) { described_class.new(context).evaluate }

    it 'remembers the indicator class' do
      expect(evaluate.indicator_class).to eq(described_class)
    end

    it 'returns NoSignal signal in case the feature flag is disabled' do
      stub_feature_flags(batched_migrations_health_status_wal: false)

      expect(evaluate).to be_a(Gitlab::Database::HealthStatus::Signals::NotAvailable)
      expect(evaluate.reason).to include('indicator disabled')
    end

    it 'returns NoSignal signal when WAL archive queue can not be calculated' do
      expect(connection).to receive(:execute).and_return([{ 'pending_wal_count' => nil }])

      expect(evaluate).to be_a(Gitlab::Database::HealthStatus::Signals::NotAvailable)
      expect(evaluate.reason).to include('WAL archive queue can not be calculated')
    end

    it 'uses primary database' do
      expect(Gitlab::Database::LoadBalancing::SessionMap.current(connection.load_balancer))
        .to receive(:use_primary).and_yield

      evaluate
    end

    context 'when WAL archive queue size is below the limit' do
      it 'returns Normal signal' do
        expect(connection).to receive(:execute).and_return([{ 'pending_wal_count' => 1 }])
        expect(evaluate).to be_a(Gitlab::Database::HealthStatus::Signals::Normal)
        expect(evaluate.reason).to include('WAL archive queue is within limit')
      end
    end

    context 'when WAL archive queue size is above the limit' do
      it 'returns Stop signal' do
        expect(connection).to receive(:execute).and_return([{ 'pending_wal_count' => 420 }])
        expect(evaluate).to be_a(Gitlab::Database::HealthStatus::Signals::Stop)
        expect(evaluate.reason).to include('WAL archive queue is too big')
      end
    end
  end
end
