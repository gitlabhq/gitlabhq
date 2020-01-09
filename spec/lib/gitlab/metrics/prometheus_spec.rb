# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Metrics::Prometheus, :prometheus do
  let(:all_metrics) { Gitlab::Metrics }
  let(:registry) { all_metrics.registry }

  after do
    all_metrics.clear_errors!
  end

  describe '#reset_registry!' do
    it 'clears existing metrics' do
      registry.counter(:test, 'test metric')

      expect(registry.metrics.count).to eq(1)

      all_metrics.reset_registry!

      expect(all_metrics.registry.metrics.count).to eq(0)
    end
  end

  describe '#error_detected!' do
    before do
      allow(all_metrics).to receive(:metrics_folder_present?).and_return(true)
      stub_application_setting(prometheus_metrics_enabled: true)
    end

    it 'disables Prometheus metrics' do
      expect(all_metrics.error?).to be_falsey
      expect(all_metrics.prometheus_metrics_enabled?).to be_truthy

      all_metrics.error_detected!

      expect(all_metrics.prometheus_metrics_enabled?).to be_falsey
      expect(all_metrics.error?).to be_truthy
    end
  end
end
