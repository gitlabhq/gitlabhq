# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe ClickHouse::MigrationSupport::Migrator, feature_category: :database do
  let(:schema_migration) do
    instance_double(
      ClickHouse::MigrationSupport::SchemaMigration,
      all_versions: [],
      create!: nil
    )
  end

  let(:logger) { instance_double(Gitlab::AppLogger, info: nil, warn: nil) }

  let(:migration) do
    double('migration', name: 'TestMigration', version: 1) # rubocop:disable RSpec/VerifiedDoubles -- delegate-defined methods are not discoverable by instance_double
  end

  subject(:migrator) { described_class.new(:up, [migration], schema_migration, nil, nil, logger) }

  before do
    allow(ClickHouse::MigrationSupport::ExclusiveLock).to receive(:execute_migration).and_yield
    allow(migrator).to receive(:sleep)
  end

  describe 'retry mechanism' do
    context 'when migration succeeds on the first attempt' do
      before do
        allow(migration).to receive(:migrate)
      end

      it 'calls migrate exactly once without sleeping' do
        migrator.migrate

        expect(migration).to have_received(:migrate).once
        expect(migrator).not_to have_received(:sleep)
      end
    end

    context 'when migration fails transiently but eventually succeeds' do
      before do
        call_count = 0
        allow(migration).to receive(:migrate) do
          call_count += 1
          raise Net::ReadTimeout, 'transient error' if call_count < described_class::MAX_RETRY_ATTEMPTS
        end
      end

      it 'succeeds and records the version' do
        expect { migrator.migrate }.not_to raise_error
        expect(schema_migration).to have_received(:create!).once
      end

      it 'sleeps with exponential backoff between retries' do
        sleep_values = []
        allow(migrator).to receive(:sleep) { |s| sleep_values << s }

        migrator.migrate

        expect(sleep_values.length).to eq(described_class::MAX_RETRY_ATTEMPTS - 1)
        expect(sleep_values.last).to be > sleep_values.first
      end

      it 'logs a warning with migration info on each retry' do
        migrator.migrate

        expect(logger).to have_received(:warn)
          .with(a_string_matching(%r{TestMigration.*attempt \d+/#{described_class::MAX_RETRY_ATTEMPTS}.*Retrying}o))
          .exactly(described_class::MAX_RETRY_ATTEMPTS - 1).times
      end
    end

    context 'when migration always fails' do
      before do
        allow(migration).to receive(:migrate).and_raise(Net::ReadTimeout, 'persistent error')
      end

      it 'raises an error after all attempts are exhausted' do
        expect do
          migrator.migrate
        end.to raise_error(StandardError, /An error has occurred, all later migrations canceled/)
      end

      it 'does not record the version' do
        expect { migrator.migrate }.to raise_error(StandardError)

        expect(schema_migration).not_to have_received(:create!)
      end
    end
  end
end
