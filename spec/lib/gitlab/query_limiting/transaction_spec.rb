# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::QueryLimiting::Transaction do
  after do
    Thread.current[described_class::THREAD_KEY] = nil
  end

  describe '.current' do
    it 'returns nil when there is no transaction' do
      expect(described_class.current).to be_nil
    end

    it 'returns the transaction when present' do
      Thread.current[described_class::THREAD_KEY] = described_class.new

      expect(described_class.current).to be_an_instance_of(described_class)
    end
  end

  describe '.run' do
    it 'runs a transaction and returns it and its return value' do
      trans, ret = described_class.run do
        10
      end

      expect(trans).to be_an_instance_of(described_class)
      expect(ret).to eq(10)
    end

    it 'removes the transaction from the current thread upon completion' do
      described_class.run do
        10
      end

      expect(Thread.current[described_class::THREAD_KEY]).to be_nil
    end
  end

  describe '#act_upon_results' do
    context 'when the query threshold is not exceeded' do
      it 'does nothing' do
        trans = described_class.new

        expect(trans).not_to receive(:raise)

        trans.act_upon_results
      end
    end

    context 'when the query threshold is exceeded' do
      let(:transaction) do
        trans = described_class.new
        trans.count = described_class::THRESHOLD + 1

        trans
      end

      it 'raises an error when this is enabled' do
        expect { transaction.act_upon_results }
          .to raise_error(described_class::ThresholdExceededError)
      end
    end
  end

  describe '#increment' do
    it 'increments the number of executed queries' do
      transaction = described_class.new

      expect { transaction.increment }.to change { transaction.count }.by(1)
    end

    it 'does not increment the number of executed queries when query limiting is disabled' do
      transaction = described_class.new

      allow(transaction).to receive(:enabled?).and_return(false)

      expect { transaction.increment }.not_to change { transaction.count }
    end
  end

  describe '#raise_error?' do
    it 'returns true in a test environment' do
      transaction = described_class.new

      expect(transaction.raise_error?).to eq(true)
    end

    it 'returns false in a production environment' do
      transaction = described_class.new

      stub_rails_env('production')

      expect(transaction.raise_error?).to eq(false)
    end
  end

  describe '#threshold_exceeded?' do
    it 'returns false when the threshold is not exceeded' do
      transaction = described_class.new

      expect(transaction.threshold_exceeded?).to eq(false)
    end

    it 'returns true when the threshold is exceeded' do
      transaction = described_class.new
      transaction.count = described_class::THRESHOLD + 1

      expect(transaction.threshold_exceeded?).to eq(true)
    end
  end

  describe '#error_message' do
    it 'returns the error message to display when the threshold is exceeded' do
      transaction = described_class.new
      transaction.count = max = described_class::THRESHOLD

      expect(transaction.error_message).to eq(
        "Too many SQL queries were executed: a maximum of #{max} " \
        "is allowed but #{max} SQL queries were executed"
      )
    end

    it 'includes a list of executed queries' do
      transaction = described_class.new
      transaction.count = max = described_class::THRESHOLD
      %w[foo bar baz].each { |sql| transaction.executed_sql(sql) }

      message = transaction.error_message

      expect(message).to start_with(
        "Too many SQL queries were executed: a maximum of #{max} " \
        "is allowed but #{max} SQL queries were executed"
      )

      expect(message).to include("0: foo", "1: bar", "2: baz")
    end

    it 'indicates if the log is truncated' do
      transaction = described_class.new
      transaction.count = described_class::THRESHOLD * 2

      message = transaction.error_message

      expect(message).to end_with('...')
    end

    it 'includes the action name in the error message when present' do
      transaction = described_class.new
      transaction.count = max = described_class::THRESHOLD
      transaction.action = 'UsersController#show'

      expect(transaction.error_message).to eq(
        "Too many SQL queries were executed in UsersController#show: " \
        "a maximum of #{max} is allowed but #{max} SQL queries were executed"
      )
    end
  end
end
