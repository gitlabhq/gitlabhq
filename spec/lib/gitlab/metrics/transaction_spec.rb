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

    it 'adds a metric' do
      expect(prometheus_metric).to receive(:increment)
      expect(described_class).to receive(:fetch_metric).with(:counter, :gitlab_transaction_event_meow_total).and_return(prometheus_metric)

      transaction.add_event(:meow)
    end

    it 'allows tracking of custom tags' do
      expect(prometheus_metric).to receive(:increment).with(hash_including(animal: "dog"))
      expect(described_class).to receive(:fetch_metric).with(:counter, :gitlab_transaction_event_bau_total).and_return(prometheus_metric)

      transaction.add_event(:bau, animal: 'dog')
    end

    context 'with sensitive tags' do
      before do
        transaction.add_event(:baubau, **sensitive_tags.merge(sane: 'yes'))
        allow(described_class).to receive(:transaction_metric).and_return(prometheus_metric)
      end

      it 'filters tags' do
        expect(prometheus_metric).not_to receive(:increment).with(hash_including(sensitive_tags))

        transaction.add_event(:baubau, **sensitive_tags.merge(sane: 'yes'))
      end
    end
  end

  describe '#increment' do
    let(:prometheus_metric) { instance_double(Prometheus::Client::Counter, increment: nil) }

    it 'adds a metric' do
      expect(prometheus_metric).to receive(:increment).with(hash_including(:action, :controller), 1)
      expect(described_class).to receive(:fetch_metric).with(:counter, :gitlab_transaction_meow_total).and_return(prometheus_metric)

      transaction.increment(:meow, 1)
    end
  end

  describe '#set' do
    let(:prometheus_metric) { instance_double(Prometheus::Client::Gauge, set: nil) }

    it 'adds a metric' do
      expect(prometheus_metric).to receive(:set).with(hash_including(:action, :controller), 1)
      expect(described_class).to receive(:fetch_metric).with(:gauge, :gitlab_transaction_meow_total).and_return(prometheus_metric)

      transaction.set(:meow, 1)
    end
  end

  describe '#get' do
    let(:prometheus_metric) { instance_double(Prometheus::Client::Counter, get: nil) }

    it 'gets a metric' do
      expect(described_class).to receive(:fetch_metric).with(:counter, :gitlab_transaction_meow_total).and_return(prometheus_metric)
      expect(prometheus_metric).to receive(:get)

      transaction.get(:meow, :counter)
    end
  end
end
