# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::Transaction do
  let(:transaction) { described_class.new }

  let(:sensitive_tags) do
    {
      path: 'private',
      branch: 'sensitive'
    }
  end

  describe '#method_call_for' do
    it 'returns a MethodCall' do
      method = transaction.method_call_for('Foo#bar', :Foo, '#bar')

      expect(method).to be_an_instance_of(Gitlab::Metrics::MethodCall)
    end
  end

  describe '#run' do
    specify { expect { transaction.run }.to raise_error(NotImplementedError) }
  end

  describe '#add_event' do
    let(:prometheus_metric) { instance_double(Prometheus::Client::Counter, increment: nil, base_labels: {}) }

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
        allow(described_class).to receive(:prometheus_metric).and_return(prometheus_metric)
      end

      it 'filters tags' do
        expect(prometheus_metric).not_to receive(:increment).with(hash_including(sensitive_tags))

        transaction.add_event(:baubau, **sensitive_tags.merge(sane: 'yes'))
      end
    end
  end

  describe '#increment' do
    let(:prometheus_metric) { instance_double(Prometheus::Client::Counter, increment: nil, base_labels: {}) }

    it 'adds a metric' do
      expect(prometheus_metric).to receive(:increment)
      expect(::Gitlab::Metrics).to receive(:counter).with(:meow, 'Meow counter', hash_including(:controller, :action)).and_return(prometheus_metric)

      transaction.increment(:meow, 1)
    end

    context 'with block' do
      it 'overrides docstring' do
        expect(::Gitlab::Metrics).to receive(:counter).with(:block_docstring, 'test', hash_including(:controller, :action)).and_return(prometheus_metric)

        transaction.increment(:block_docstring, 1) do
          docstring 'test'
        end
      end

      it 'overrides labels' do
        expect(::Gitlab::Metrics).to receive(:counter).with(:block_labels, 'Block labels counter', hash_including(:controller, :action, :sane)).and_return(prometheus_metric)

        labels = { sane: 'yes' }
        transaction.increment(:block_labels, 1, labels) do
          label_keys %i(sane)
        end
      end

      it 'filters sensitive tags' do
        expect(::Gitlab::Metrics).to receive(:counter).with(:metric_with_sensitive_block, 'Metric with sensitive block counter', hash_excluding(sensitive_tags)).and_return(prometheus_metric)

        labels_keys = sensitive_tags.keys
        transaction.increment(:metric_with_sensitive_block, 1, sensitive_tags) do
          label_keys labels_keys
        end
      end
    end
  end

  describe '#set' do
    let(:prometheus_metric) { instance_double(Prometheus::Client::Gauge, set: nil, base_labels: {}) }

    it 'adds a metric' do
      expect(prometheus_metric).to receive(:set)
      expect(::Gitlab::Metrics).to receive(:gauge).with(:meow_set, 'Meow set gauge', hash_including(:controller, :action), :all).and_return(prometheus_metric)

      transaction.set(:meow_set, 1)
    end

    context 'with block' do
      it 'overrides docstring' do
        expect(::Gitlab::Metrics).to receive(:gauge).with(:block_docstring_set, 'test', hash_including(:controller, :action), :all).and_return(prometheus_metric)

        transaction.set(:block_docstring_set, 1) do
          docstring 'test'
        end
      end

      it 'overrides labels' do
        expect(::Gitlab::Metrics).to receive(:gauge).with(:block_labels_set, 'Block labels set gauge', hash_including(:controller, :action, :sane), :all).and_return(prometheus_metric)

        labels = { sane: 'yes' }
        transaction.set(:block_labels_set, 1, labels) do
          label_keys %i(sane)
        end
      end

      it 'filters sensitive tags' do
        expect(::Gitlab::Metrics).to receive(:gauge).with(:metric_set_with_sensitive_block, 'Metric set with sensitive block gauge', hash_excluding(sensitive_tags), :all).and_return(prometheus_metric)

        label_keys = sensitive_tags.keys
        transaction.set(:metric_set_with_sensitive_block, 1, sensitive_tags) do
          label_keys label_keys
        end
      end
    end
  end

  describe '#observe' do
    let(:prometheus_metric) { instance_double(Prometheus::Client::Histogram, observe: nil, base_labels: {}) }

    it 'adds a metric' do
      expect(prometheus_metric).to receive(:observe)
      expect(::Gitlab::Metrics).to receive(:histogram).with(:meow_observe, 'Meow observe histogram', hash_including(:controller, :action), kind_of(Array)).and_return(prometheus_metric)

      transaction.observe(:meow_observe, 1)
    end

    context 'with block' do
      it 'overrides docstring' do
        expect(::Gitlab::Metrics).to receive(:histogram).with(:block_docstring_observe, 'test', hash_including(:controller, :action), kind_of(Array)).and_return(prometheus_metric)

        transaction.observe(:block_docstring_observe, 1) do
          docstring 'test'
        end
      end

      it 'overrides labels' do
        expect(::Gitlab::Metrics).to receive(:histogram).with(:block_labels_observe, 'Block labels observe histogram', hash_including(:controller, :action, :sane), kind_of(Array)).and_return(prometheus_metric)

        labels = { sane: 'yes' }
        transaction.observe(:block_labels_observe, 1, labels) do
          label_keys %i(sane)
        end
      end

      it 'filters sensitive tags' do
        expect(::Gitlab::Metrics).to receive(:histogram).with(:metric_observe_with_sensitive_block, 'Metric observe with sensitive block histogram', hash_excluding(sensitive_tags), kind_of(Array)).and_return(prometheus_metric)

        label_keys = sensitive_tags.keys
        transaction.observe(:metric_observe_with_sensitive_block, 1, sensitive_tags) do
          label_keys label_keys
        end
      end
    end
  end
end
