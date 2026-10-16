# frozen_string_literal: true

require 'spec_helper'

# :delete because a session-level SET is refused inside the per-example transaction.
RSpec.describe Gitlab::Database::Session::Settings, :delete, feature_category: :database do
  let(:connection) { ApplicationRecord.connection }

  def current_statement_timeout
    connection.select_value('SHOW statement_timeout')
  end

  def load_balancing_session
    Gitlab::Database::LoadBalancing::SessionMap.current(connection.load_balancer)
  end

  # A session-level SET outlives the example, so put the original value back for later examples.
  around do |example|
    original = current_statement_timeout
    example.run
  ensure
    connection.execute("SET statement_timeout = #{connection.quote(original)}")
  end

  describe '.with' do
    before do
      connection.execute("SET statement_timeout = '2s'")
    end

    it 'sets a configuration value inside the block and restores it afterwards' do
      described_class.with('statement_timeout', '5s') do
        expect(current_statement_timeout).to eq('5s')
      end

      expect(current_statement_timeout).to eq('2s')
    end

    it 'restores the original value with SET instead of RESET' do
      allow(connection).to receive(:exec_query).and_call_original
      expect(connection).not_to receive(:exec_query).with(/RESET/)

      described_class.with('statement_timeout', '5s') { 1 + 1 }

      expect(current_statement_timeout).to eq('2s')
    end

    it 'restores the original value when the block raises' do
      expect { described_class.with('statement_timeout', '5s') { raise 'boom' } }.to raise_error('boom')

      expect(current_statement_timeout).to eq('2s')
    end

    it 'does not restore anything when reading the current value fails' do
      allow(connection).to receive(:select_value).and_call_original
      allow(connection).to receive(:select_value).with('SHOW statement_timeout')
        .and_raise(ActiveRecord::StatementInvalid, 'boom')

      expect(connection).not_to receive(:exec_query)
      expect { described_class.with('statement_timeout', '5s') { 1 + 1 } }
        .to raise_error(ActiveRecord::StatementInvalid, 'boom')
    end

    it 'raises an error when config is not allowed' do
      expect { described_class.with('lock_timeout', '1s') { 1 + 1 } }
        .to raise_error(described_class::InvalidConfigError)
    end

    it 'raises an error inside a transaction without touching the setting' do
      expect(connection).not_to receive(:exec_query)

      connection.transaction do
        expect { described_class.with('statement_timeout', '5s') { 1 + 1 } }
          .to raise_error(described_class::TransactionOpenError, /use Gitlab::Database::Transaction::Settings/)
      end
    end

    it 'runs the block on the primary' do
      was_using_primary = load_balancing_session.use_primary?

      described_class.with('statement_timeout', '5s') do
        expect(load_balancing_session.use_primary?).to be(true)
      end

      expect(load_balancing_session.use_primary?).to be(was_using_primary)
    end

    it 'yields directly for a connection without a load balancer' do
      raw_connection = connection.load_balancer.read_write { |raw| raw }

      expect(Gitlab::Database::LoadBalancing::SessionMap).not_to receive(:current)

      described_class.with('statement_timeout', '5s', raw_connection) do
        expect(raw_connection.select_value('SHOW statement_timeout')).to eq('5s')
      end
    end
  end
end
