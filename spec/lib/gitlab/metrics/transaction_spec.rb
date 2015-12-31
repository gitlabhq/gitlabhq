require 'spec_helper'

describe Gitlab::Metrics::Transaction do
  let(:transaction) { described_class.new('rspec') }

  describe '#duration' do
    it 'returns the duration of a transaction in seconds' do
      transaction.run { sleep(0.5) }

      expect(transaction.duration).to be >= 0.5
    end
  end

  describe '#run' do
    it 'yields the supplied block' do
      expect { |b| transaction.run(&b) }.to yield_control
    end

    it 'stores the transaction in the current thread' do
      transaction.run do
        expect(Thread.current[described_class::THREAD_KEY]).to eq(transaction)
      end
    end

    it 'removes the transaction from the current thread upon completion' do
      transaction.run { }

      expect(Thread.current[described_class::THREAD_KEY]).to be_nil
    end
  end

  describe '#add_metric' do
    it 'adds a metric tagged with the transaction UUID' do
      expect(Gitlab::Metrics::Metric).to receive(:new).
        with('foo', { number: 10 }, { transaction_id: transaction.uuid })

      transaction.add_metric('foo', number: 10)
    end
  end

  describe '#add_tag' do
    it 'adds a tag' do
      transaction.add_tag(:foo, 'bar')

      expect(transaction.tags).to eq({ foo: 'bar' })
    end
  end

  describe '#finish' do
    it 'tracks the transaction details and submits them to Sidekiq' do
      expect(transaction).to receive(:track_self)
      expect(transaction).to receive(:submit)

      transaction.finish
    end
  end

  describe '#track_self' do
    it 'adds a metric for the transaction itself' do
      expect(transaction).to receive(:add_metric).
        with('rspec', { duration: transaction.duration }, {})

      transaction.track_self
    end
  end

  describe '#submit' do
    it 'submits the metrics to Sidekiq' do
      transaction.track_self

      expect(Gitlab::Metrics).to receive(:submit_metrics).
        with([an_instance_of(Hash)])

      transaction.submit
    end
  end
end
