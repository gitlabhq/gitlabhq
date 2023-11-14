# frozen_string_literal: true

RSpec.shared_examples 'transaction metrics with labels' do
  let(:sensitive_tags) do
    {
      path: 'private',
      branch: 'sensitive'
    }
  end

  around do |example|
    described_class.reload_metric!
    example.run
    described_class.reload_metric!
  end

  describe '.prometheus_metric' do
    let(:prometheus_metric) { instance_double(Prometheus::Client::Histogram, observe: nil, base_labels: {}) }

    it 'adds a metric' do
      expect(::Gitlab::Metrics).to receive(:histogram).with(
        :meow_observe, 'Meow observe histogram', hash_including(*described_class::BASE_LABEL_KEYS), be_a(Array)
      ).and_return(prometheus_metric)

      expect do |block|
        metric = described_class.prometheus_metric(:meow_observe, :histogram, &block)
        expect(metric).to be(prometheus_metric)
      end.to yield_control
    end
  end

  describe '#method_call_for' do
    it 'returns a MethodCall' do
      method = transaction_obj.method_call_for('Foo#bar', :Foo, '#bar')

      expect(method).to be_an_instance_of(Gitlab::Metrics::MethodCall)
    end
  end

  describe '#add_event' do
    let(:prometheus_metric) { instance_double(Prometheus::Client::Counter, increment: nil, base_labels: {}) }

    it 'adds a metric' do
      expect(prometheus_metric).to receive(:increment).with(labels)
      expect(described_class).to receive(:fetch_metric).with(:counter, :gitlab_transaction_event_meow_total).and_return(prometheus_metric)

      transaction_obj.add_event(:meow)
    end

    it 'allows tracking of custom tags' do
      expect(prometheus_metric).to receive(:increment).with(labels.merge(animal: "dog"))
      expect(described_class).to receive(:fetch_metric).with(:counter, :gitlab_transaction_event_bau_total).and_return(prometheus_metric)

      transaction_obj.add_event(:bau, animal: 'dog')
    end

    context 'with sensitive tags' do
      it 'filters tags' do
        expect(described_class).to receive(:fetch_metric).with(:counter, :gitlab_transaction_event_bau_total).and_return(prometheus_metric)
        expect(prometheus_metric).not_to receive(:increment).with(hash_including(sensitive_tags))

        transaction_obj.add_event(:bau, **sensitive_tags.merge(sane: 'yes'))
      end
    end
  end

  describe '#increment' do
    let(:prometheus_metric) { instance_double(Prometheus::Client::Counter, increment: nil, base_labels: {}) }

    it 'adds a metric' do
      expect(::Gitlab::Metrics).to receive(:counter).with(
        :meow, 'Meow counter', hash_including(*described_class::BASE_LABEL_KEYS)
      ).and_return(prometheus_metric)
      expect(prometheus_metric).to receive(:increment).with(labels, 1)

      transaction_obj.increment(:meow, 1)
    end

    context 'with block' do
      it 'overrides docstring' do
        expect(::Gitlab::Metrics).to receive(:counter).with(
          :block_docstring, 'test', hash_including(*described_class::BASE_LABEL_KEYS)
        ).and_return(prometheus_metric)
        expect(prometheus_metric).to receive(:increment).with(labels, 1)

        transaction_obj.increment(:block_docstring, 1) do
          docstring 'test'
        end
      end

      it 'overrides labels' do
        expect(::Gitlab::Metrics).to receive(:counter).with(
          :block_labels, 'Block labels counter', hash_including(*described_class::BASE_LABEL_KEYS)
        ).and_return(prometheus_metric)
        expect(prometheus_metric).to receive(:increment).with(labels.merge(sane: 'yes'), 1)

        transaction_obj.increment(:block_labels, 1, sane: 'yes') do
          label_keys %i[sane]
        end
      end

      it 'filters sensitive tags' do
        labels_keys = sensitive_tags.keys

        expect(::Gitlab::Metrics).to receive(:counter).with(
          :metric_with_sensitive_block, 'Metric with sensitive block counter', hash_excluding(labels_keys)
        ).and_return(prometheus_metric)
        expect(prometheus_metric).to receive(:increment).with(labels, 1)

        transaction_obj.increment(:metric_with_sensitive_block, 1, sensitive_tags) do
          label_keys labels_keys
        end
      end
    end
  end

  describe '#set' do
    let(:prometheus_metric) { instance_double(Prometheus::Client::Gauge, set: nil, base_labels: {}) }

    it 'adds a metric' do
      expect(::Gitlab::Metrics).to receive(:gauge).with(
        :meow_set, 'Meow set gauge', hash_including(*described_class::BASE_LABEL_KEYS), :all
      ).and_return(prometheus_metric)
      expect(prometheus_metric).to receive(:set).with(labels, 99)

      transaction_obj.set(:meow_set, 99)
    end

    context 'with block' do
      it 'overrides docstring' do
        expect(::Gitlab::Metrics).to receive(:gauge).with(
          :block_docstring_set, 'test', hash_including(*described_class::BASE_LABEL_KEYS), :all
        ).and_return(prometheus_metric)
        expect(prometheus_metric).to receive(:set).with(labels, 99)

        transaction_obj.set(:block_docstring_set, 99) do
          docstring 'test'
        end
      end

      it 'overrides labels' do
        expect(::Gitlab::Metrics).to receive(:gauge).with(
          :block_labels_set, 'Block labels set gauge', hash_including(*described_class::BASE_LABEL_KEYS), :all
        ).and_return(prometheus_metric)
        expect(prometheus_metric).to receive(:set).with(labels.merge(sane: 'yes'), 99)

        transaction_obj.set(:block_labels_set, 99, sane: 'yes') do
          label_keys %i[sane]
        end
      end

      it 'filters sensitive tags' do
        labels_keys = sensitive_tags.keys

        expect(::Gitlab::Metrics).to receive(:gauge).with(
          :metric_set_with_sensitive_block, 'Metric set with sensitive block gauge', hash_excluding(*labels_keys), :all
        ).and_return(prometheus_metric)
        expect(prometheus_metric).to receive(:set).with(labels, 99)

        transaction_obj.set(:metric_set_with_sensitive_block, 99, sensitive_tags) do
          label_keys label_keys
        end
      end
    end
  end

  describe '#observe' do
    let(:prometheus_metric) { instance_double(Prometheus::Client::Histogram, observe: nil, base_labels: {}) }

    it 'adds a metric' do
      expect(::Gitlab::Metrics).to receive(:histogram).with(
        :meow_observe, 'Meow observe histogram', hash_including(*described_class::BASE_LABEL_KEYS), kind_of(Array)
      ).and_return(prometheus_metric)
      expect(prometheus_metric).to receive(:observe).with(labels, 2.0)

      transaction_obj.observe(:meow_observe, 2.0)
    end

    context 'with block' do
      it 'overrides docstring' do
        expect(::Gitlab::Metrics).to receive(:histogram).with(
          :block_docstring_observe, 'test', hash_including(*described_class::BASE_LABEL_KEYS), kind_of(Array)
        ).and_return(prometheus_metric)
        expect(prometheus_metric).to receive(:observe).with(labels, 2.0)

        transaction_obj.observe(:block_docstring_observe, 2.0) do
          docstring 'test'
        end
      end

      it 'overrides labels' do
        expect(::Gitlab::Metrics).to receive(:histogram).with(
          :block_labels_observe, 'Block labels observe histogram', hash_including(*described_class::BASE_LABEL_KEYS), kind_of(Array)
        ).and_return(prometheus_metric)
        expect(prometheus_metric).to receive(:observe).with(labels.merge(sane: 'yes'), 2.0)

        transaction_obj.observe(:block_labels_observe, 2.0, sane: 'yes') do
          label_keys %i[sane]
        end
      end

      it 'filters sensitive tags' do
        labels_keys = sensitive_tags.keys

        expect(::Gitlab::Metrics).to receive(:histogram).with(
          :metric_observe_with_sensitive_block,
          'Metric observe with sensitive block histogram',
          hash_excluding(labels_keys),
          kind_of(Array)
        ).and_return(prometheus_metric)
        expect(prometheus_metric).to receive(:observe).with(labels, 2.0)

        transaction_obj.observe(:metric_observe_with_sensitive_block, 2.0, sensitive_tags) do
          label_keys label_keys
        end
      end
    end
  end
end
