# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::Metrics::Labkit, :prometheus, feature_category: :scalability do
  let(:all_metrics) do
    Class.new do
      include ::Gitlab::Metrics::Labkit
    end
  end

  let(:client) { all_metrics.client }

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
    after do
      Labkit::Metrics::Client.enable!
    end

    it 'disables Prometheus metrics' do
      stub_application_setting(prometheus_metrics_enabled: true)

      expect(client.enabled?).to be_truthy
      expect(all_metrics.prometheus_metrics_enabled?).to be_truthy

      all_metrics.error_detected!

      expect(client.enabled?).to be_falsey
      expect(all_metrics.prometheus_metrics_enabled?).to be_falsey
    end
  end
end
