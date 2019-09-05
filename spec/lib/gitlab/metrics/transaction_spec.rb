# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Metrics::Transaction do
  let(:transaction) { described_class.new }
  let(:metric) { transaction.metrics[0] }

  let(:sensitive_tags) do
    {
      path: 'private',
      branch: 'sensitive'
    }
  end

  shared_examples 'tag filter' do |sane_tags|
    it 'filters potentially sensitive tags' do
      expect(metric.tags).to eq(sane_tags)
    end
  end

  describe '#duration' do
    it 'returns the duration of a transaction in seconds' do
      transaction.run { }

      expect(transaction.duration).to be > 0
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

  describe '#add_metric' do
    it 'adds a metric to the transaction' do
      transaction.add_metric('foo', value: 1)

      expect(metric.series).to eq('rails_foo')
      expect(metric.tags).to eq({})
      expect(metric.values).to eq(value: 1)
    end

    context 'with sensitive tags' do
      before do
        transaction
          .add_metric('foo', { value: 1 }, **sensitive_tags.merge(sane: 'yes'))
      end

      it_behaves_like 'tag filter', sane: 'yes'
    end
  end

  describe '#method_call_for' do
    it 'returns a MethodCall' do
      method = transaction.method_call_for('Foo#bar', :Foo, '#bar')

      expect(method).to be_an_instance_of(Gitlab::Metrics::MethodCall)
    end
  end

  describe '#increment' do
    it 'increments a counter' do
      transaction.increment(:time, 1)
      transaction.increment(:time, 2)

      values = metric_values(time: 3)

      expect(transaction).to receive(:add_metric)
        .with('transactions', values, {})

      transaction.track_self
    end
  end

  describe '#set' do
    it 'sets a value' do
      transaction.set(:number, 10)

      values = metric_values(number: 10)

      expect(transaction).to receive(:add_metric)
        .with('transactions', values, {})

      transaction.track_self
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
      values = metric_values

      expect(transaction).to receive(:add_metric)
        .with('transactions', values, {})

      transaction.track_self
    end
  end

  describe '#submit' do
    it 'submits the metrics to Sidekiq' do
      transaction.track_self

      expect(Gitlab::Metrics).to receive(:submit_metrics)
        .with([an_instance_of(Hash)])

      transaction.submit
    end

    it 'adds the action as a tag for every metric' do
      allow(transaction)
        .to receive(:labels)
        .and_return(controller: 'Foo', action: 'bar')

      transaction.track_self

      hash = {
        series: 'rails_transactions',
        tags: { action: 'Foo#bar' },
        values: metric_values,
        timestamp: a_kind_of(Integer)
      }

      expect(Gitlab::Metrics).to receive(:submit_metrics)
        .with([hash])

      transaction.submit
    end

    it 'does not add an action tag for events' do
      allow(transaction)
        .to receive(:labels)
        .and_return(controller: 'Foo', action: 'bar')

      transaction.add_event(:meow)

      hash = {
        series: 'events',
        tags: { event: :meow },
        values: { count: 1 },
        timestamp: a_kind_of(Integer)
      }

      expect(Gitlab::Metrics).to receive(:submit_metrics)
        .with([hash])

      transaction.submit
    end
  end

  describe '#add_event' do
    it 'adds a metric' do
      transaction.add_event(:meow)

      expect(metric).to be_an_instance_of(Gitlab::Metrics::Metric)
    end

    it "does not prefix the metric's series name" do
      transaction.add_event(:meow)

      expect(metric.series).to eq(described_class::EVENT_SERIES)
    end

    it 'tracks a counter for every event' do
      transaction.add_event(:meow)

      expect(metric.values).to eq(count: 1)
    end

    it 'tracks the event name' do
      transaction.add_event(:meow)

      expect(metric.tags).to eq(event: :meow)
    end

    it 'allows tracking of custom tags' do
      transaction.add_event(:bau, animal: 'dog')

      expect(metric.tags).to eq(event: :bau, animal: 'dog')
    end

    context 'with sensitive tags' do
      before do
        transaction.add_event(:baubau, **sensitive_tags.merge(sane: 'yes'))
      end

      it_behaves_like 'tag filter', event: :baubau, sane: 'yes'
    end
  end

  private

  def metric_values(opts = {})
    {
      duration: 0.0,
      allocated_memory: a_kind_of(Numeric)
    }.merge(opts)
  end
end
