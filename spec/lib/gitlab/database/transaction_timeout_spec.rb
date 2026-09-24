# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::TransactionTimeout, feature_category: :database do
  using RSpec::Parameterized::TableSyntax

  let(:connection) { ActiveRecord::Base.connection }

  describe '.supported?' do
    where(:database_version, :supported) do
      16_00_00 | false
      16_09_00 | false
      17_00_00 | true
      17_08_00 | true
      18_04_00 | true
    end

    with_them do
      before do
        allow(connection).to receive(:database_version).and_return(database_version)
      end

      it { expect(described_class.supported?(connection)).to be(supported) }
    end
  end

  context 'when the database is PostgreSQL 17 or later' do
    before do
      allow(connection).to receive(:database_version).and_return(17_00_00)
    end

    describe '.set' do
      context 'when no transaction is open' do
        before do
          allow(connection).to receive(:transaction_open?).and_return(false)
        end

        it 'sets transaction_timeout to the given duration for the session' do
          expect(connection).to receive(:execute).with("SET transaction_timeout TO '86400s'")

          described_class.set(connection, 24.hours)
        end
      end

      context 'when a transaction is open' do
        before do
          allow(connection).to receive(:transaction_open?).and_return(true)
        end

        it 'disarms the running timer before setting it for the current transaction' do
          expect(connection).to receive(:execute).with('SET LOCAL transaction_timeout TO 0').ordered
          expect(connection).to receive(:execute).with("SET LOCAL transaction_timeout TO '3600s'").ordered

          described_class.set(connection, 1.hour, local: true)
        end

        it 'disarms the running timer before a session-level set too' do
          expect(connection).to receive(:execute).with('SET LOCAL transaction_timeout TO 0').ordered
          expect(connection).to receive(:execute).with("SET transaction_timeout TO '3600s'").ordered

          described_class.set(connection, 1.hour)
        end
      end
    end

    describe '.disable' do
      it 'disables transaction_timeout for the session' do
        expect(connection).to receive(:execute).with("SET transaction_timeout TO '0s'")

        described_class.disable(connection)
      end

      it 'disables transaction_timeout for the current transaction only when local' do
        expect(connection).to receive(:execute).with("SET LOCAL transaction_timeout TO '0s'")

        described_class.disable(connection, local: true)
      end
    end

    describe '.reset' do
      it 'resets transaction_timeout to its default' do
        expect(connection).to receive(:execute).with('RESET transaction_timeout')

        described_class.reset(connection)
      end
    end
  end

  context 'when the database is older than PostgreSQL 17' do
    before do
      skip 'needs a PostgreSQL 17 or later server to read the setting' unless described_class.supported?(connection)

      allow(connection).to receive(:database_version).and_return(16_09_00)
    end

    it 'does not run any statement or change the setting' do
      expect(connection).not_to receive(:execute)

      expect do
        described_class.set(connection, 1.hour)
        described_class.disable(connection)
        described_class.disable(connection, local: true)
        described_class.reset(connection)
      end.not_to change { connection.select_value('SHOW transaction_timeout') }
    end
  end

  context 'with a real PostgreSQL 17 or later connection' do
    before do
      skip 'transaction_timeout requires PostgreSQL 17 or later' unless described_class.supported?(connection)

      connection.execute("SET transaction_timeout TO '1h'")
    end

    after do
      connection.execute('RESET transaction_timeout')
    end

    it 'disables the setting for the session' do
      expect { described_class.disable(connection) }.to change { current_timeout }.from('1h').to('0')
    end

    it 'sets the given duration for the session' do
      expect { described_class.set(connection, 2.hours) }.to change { current_timeout }.from('1h').to('2h')
    end

    it 'outlives the session deadline after a local set inside a transaction' do
      # The spec's own transaction already armed a timer; only a zero lets the 1s one take over.
      connection.execute('SET transaction_timeout TO 0')
      connection.execute("SET transaction_timeout TO '1s'")

      expect do
        connection.transaction(requires_new: true) do
          described_class.set(connection, 10.seconds, local: true)
          connection.execute('SELECT pg_sleep(1.5)')
        end
      end.not_to raise_error
    end

    it 'scopes a local disable to the enclosing transaction' do
      connection.transaction(requires_new: true) do
        described_class.disable(connection, local: true)

        expect(current_timeout).to eq('0')

        raise ActiveRecord::Rollback
      end

      expect(current_timeout).to eq('1h')
    end

    def current_timeout
      connection.select_value('SHOW transaction_timeout')
    end
  end
end
