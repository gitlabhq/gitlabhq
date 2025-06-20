# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::Metrics::Labkit, :prometheus, feature_category: :scalability do
  let(:all_metrics) do
    Class.new do
      include ::Gitlab::Metrics::Labkit
    end
  end

  let(:client) { all_metrics.client }

  after do
    all_metrics.clear_errors!
  end

  describe '#reset_registry!' do
    it 'clears existing metrics' do
      counter = client.counter(:test, 'test metric')
      counter.increment

      expect(counter.get).to eq(1)

      all_metrics.reset_registry!

      expect(counter.get).to eq(0)
    end
  end

  describe '#error_detected!' do
    it 'disables Prometheus metrics' do
      stub_application_setting(prometheus_metrics_enabled: true)

      expect(all_metrics.error?).to be_falsey
      expect(all_metrics.prometheus_metrics_enabled?).to be_truthy

      all_metrics.error_detected!

      expect(all_metrics.prometheus_metrics_enabled?).to be_falsey
      expect(all_metrics.error?).to be_truthy
    end
  end
end
