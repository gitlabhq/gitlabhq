# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::PrometheusEnabledMetric, feature_category: :service_ping do
  before do
    allow(Gitlab::Prometheus::Internal).to receive(:prometheus_enabled?).and_return(expected_value)
  end

  [true, false].each do |setting|
    context "when the setting is #{setting}" do
      let(:expected_value) { setting }

      it_behaves_like 'a correct instrumented metric value', { time_frame: 'none' }
    end
  end
end
