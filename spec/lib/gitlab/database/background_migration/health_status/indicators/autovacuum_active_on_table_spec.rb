# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::BackgroundMigration::HealthStatus::Indicators::AutovacuumActiveOnTable,
  feature_category: :database do
  include Database::DatabaseHelpers

  let(:connection) { Gitlab::Database.database_base_models[:main].connection }

  around do |example|
    Gitlab::Database::SharedModel.using_connection(connection) do
      example.run
    end
  end

  describe '#evaluate' do
    subject { described_class.new(context).evaluate }

    before do
      swapout_view_for_table(:postgres_autovacuum_activity, connection: connection)
    end

    let(:tables) { [table] }
    let(:table) { 'users' }
    let(:context) { Gitlab::Database::BackgroundMigration::HealthStatus::Context.new(connection, tables) }

    context 'without autovacuum activity' do
      it 'returns Normal signal' do
        expect(subject).to be_a(Gitlab::Database::BackgroundMigration::HealthStatus::Signals::Normal)
      end

      it 'remembers the indicator class' do
        expect(subject.indicator_class).to eq(described_class)
      end
    end

    context 'with autovacuum activity' do
      before do
        create(:postgres_autovacuum_activity, table: table, table_identifier: "public.#{table}")
      end

      it 'returns Stop signal' do
        expect(subject).to be_a(Gitlab::Database::BackgroundMigration::HealthStatus::Signals::Stop)
      end

      it 'explains why' do
        expect(subject.reason).to include('autovacuum running on: table public.users')
      end

      it 'remembers the indicator class' do
        expect(subject.indicator_class).to eq(described_class)
      end

      it 'returns NoSignal signal in case the feature flag is disabled' do
        stub_feature_flags(batched_migrations_health_status_autovacuum: false)

        expect(subject).to be_a(Gitlab::Database::BackgroundMigration::HealthStatus::Signals::NotAvailable)
      end
    end
  end
end
