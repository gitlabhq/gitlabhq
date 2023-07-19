# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::GitalyApdexMetric, feature_category: :service_ping do
  let(:prometheus_client) { instance_double(Gitlab::PrometheusClient) }
  let(:metric) { described_class.new(time_frame: 'none') }

  before do
    allow(prometheus_client).to receive(:query)
      .with(/gitlab_usage_ping:gitaly_apdex:ratio_avg_over_time_5m/)
      .and_return(
        [
          { 'metric' => {},
            'value' => [1616016381.473, '0.95'] }
        ])
    # rubocop:disable RSpec/AnyInstanceOf
    allow_any_instance_of(Gitlab::Utils::UsageData).to receive(:with_prometheus_client).and_yield(prometheus_client)
    # rubocop:enable RSpec/AnyInstanceOf
  end

  it 'gathers gitaly apdex', :aggregate_failures do
    expect(metric.value).to be_within(0.001).of(0.95)
  end
end
