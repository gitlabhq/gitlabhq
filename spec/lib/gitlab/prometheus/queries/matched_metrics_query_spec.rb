require 'spec_helper'

describe Gitlab::Prometheus::Queries::MatchedMetricsQuery, lib: true do
  let(:environment) { create(:environment, slug: 'environment-slug') }
  let(:deployment) { create(:deployment, environment: environment) }

  let(:client) { double('prometheus_client') }
  subject { described_class.new(client) }

  around do |example|
    time_without_subsecond_values = Time.local(2008, 9, 1, 12, 0, 0)
    Timecop.freeze(time_without_subsecond_values) { example.run }
  end

  let(:metric_group_class) { Gitlab::Prometheus::MetricGroup }
  let(:metric_class) { Gitlab::Prometheus::Metric }

  let(:simple_metrics) do
    [
      metric_class.new('title', ['metrica', 'metricb'], '1', 'y_label', [{ :query_range => 'avg' }])
    ]
  end

  let(:simple_metric_group) do
    metric_group_class.new('name', 1, simple_metrics)
  end

  let(:xx) do
    [{
       '__name__': 'metrica',
       'environment': 'mattermost'
     },
     {
       '__name__': 'metricb',
       'environment': 'mattermost'
     }]
  end

  before do
    allow(metric_group_class).to receive(:all).and_return([simple_metric_group])

    allow(client).to receive(:label_values).and_return(['metrica', 'metricb'])
    allow(client).to receive(:series).and_return(xx)
  end

  it "something something" do

    expect(subject.query).to eq("asf")
  end
end
