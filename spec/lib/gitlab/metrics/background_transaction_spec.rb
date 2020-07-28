# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::BackgroundTransaction do
  let(:test_worker_class) { double(:class, name: 'TestWorker') }
  let(:prometheus_metric) { instance_double(Prometheus::Client::Metric, base_labels: {}) }

  before do
    allow(described_class).to receive(:prometheus_metric).and_return(prometheus_metric)
  end

  subject { described_class.new(test_worker_class) }

  RSpec.shared_examples 'metric with worker labels' do |metric_method|
    it 'measures with correct labels and value' do
      value = 1
      expect(prometheus_metric).to receive(metric_method).with({ controller: 'TestWorker', action: 'perform', feature_category: '' }, value)

      subject.send(metric_method, :bau, value)
    end
  end

  describe '#label' do
    it 'returns labels based on class name' do
      expect(subject.labels).to eq(controller: 'TestWorker', action: 'perform', feature_category: '')
    end

    it 'contains only the labels defined for metrics' do
      expect(subject.labels.keys).to contain_exactly(*described_class.superclass::BASE_LABEL_KEYS)
    end

    it 'includes the feature category if there is one' do
      expect(test_worker_class).to receive(:get_feature_category).and_return('source_code_management')
      expect(subject.labels).to include(feature_category: 'source_code_management')
    end
  end

  describe '#increment' do
    let(:prometheus_metric) { instance_double(Prometheus::Client::Counter, :increment, base_labels: {}) }

    it_behaves_like 'metric with worker labels', :increment
  end

  describe '#set' do
    let(:prometheus_metric) { instance_double(Prometheus::Client::Gauge, :set, base_labels: {}) }

    it_behaves_like 'metric with worker labels', :set
  end

  describe '#observe' do
    let(:prometheus_metric) { instance_double(Prometheus::Client::Histogram, :observe, base_labels: {}) }

    it_behaves_like 'metric with worker labels', :observe
  end
end
