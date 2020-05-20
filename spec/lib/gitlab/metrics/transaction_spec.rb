# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Metrics::Transaction do
  let(:transaction) { described_class.new }

  let(:sensitive_tags) do
    {
      path: 'private',
      branch: 'sensitive'
    }
  end

  describe '#duration' do
    it 'returns the duration of a transaction in seconds' do
      transaction.run { }

      expect(transaction.duration).to be > 0
    end
  end

  describe '#thread_cpu_duration' do
    it 'returns the duration of a transaction in seconds' do
      transaction.run { }

      expect(transaction.thread_cpu_duration).to be > 0
    end
  end

  describe '#allocated_memory' do
    it 'returns the allocated memory in bytes' do
      transaction.run { 'a' * 32 }

      expect(transaction.allocated_memory).to be_a_kind_of(Numeric)
    end
  end

  describe '#run' do
    it 'yields the supplied block' do
      expect { |b| transaction.run(&b) }.to yield_control
    end

    it 'stores the transaction in the current thread' do
      transaction.run do
        expect(described_class.current).to eq(transaction)
      end
    end

    it 'removes the transaction from the current thread upon completion' do
      transaction.run { }

      expect(described_class.current).to be_nil
    end
  end

  describe '#method_call_for' do
    it 'returns a MethodCall' do
      method = transaction.method_call_for('Foo#bar', :Foo, '#bar')

      expect(method).to be_an_instance_of(Gitlab::Metrics::MethodCall)
    end
  end

  describe '#add_event' do
    let(:prometheus_metric) { instance_double(Prometheus::Client::Counter, increment: nil) }

    before do
      allow(described_class).to receive(:transaction_metric).and_return(prometheus_metric)
    end

    it 'adds a metric' do
      expect(prometheus_metric).to receive(:increment)

      transaction.add_event(:meow)
    end

    it 'allows tracking of custom tags' do
      expect(prometheus_metric).to receive(:increment).with(hash_including(animal: "dog"))

      transaction.add_event(:bau, animal: 'dog')
    end

    context 'with sensitive tags' do
      before do
        transaction.add_event(:baubau, **sensitive_tags.merge(sane: 'yes'))
      end

      it 'filters tags' do
        expect(prometheus_metric).not_to receive(:increment).with(hash_including(sensitive_tags))

        transaction.add_event(:baubau, **sensitive_tags.merge(sane: 'yes'))
      end
    end
  end
end
