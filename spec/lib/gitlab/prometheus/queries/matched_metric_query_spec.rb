require 'spec_helper'

describe Gitlab::Prometheus::Queries::MatchedMetricQuery do
  include Prometheus::MetricBuilders

  let(:metric_group_class) { Gitlab::Prometheus::MetricGroup }
  let(:metric_class) { Gitlab::Prometheus::Metric }

  def series_info_with_environment(*more_metrics)
    %w{metric_a metric_b}.concat(more_metrics).map { |metric_name| { '__name__' => metric_name, 'environment' => '' } }
  end

  let(:metric_names) { %w{metric_a metric_b} }
  let(:series_info_without_environment) do
    [{ '__name__' => 'metric_a' },
     { '__name__' => 'metric_b' }]
  end
  let(:partialy_empty_series_info) { [{ '__name__' => 'metric_a', 'environment' => '' }] }
  let(:empty_series_info) { [] }

  let(:client) { double('prometheus_client') }

  subject { described_class.new(client) }

  context 'with one group where two metrics is found' do
    before do
      allow(metric_group_class).to receive(:common_metrics).and_return([simple_metric_group])
      allow(client).to receive(:label_values).and_return(metric_names)
    end

    context 'both metrics in the group pass requirements' do
      before do
        allow(client).to receive(:series).and_return(series_info_with_environment)
      end

      it 'responds with both metrics as actve' do
        expect(subject.query).to eq([{ group: 'name', priority: 1, active_metrics: 2, metrics_missing_requirements: 0 }])
      end
    end

    context 'none of the metrics pass requirements' do
      before do
        allow(client).to receive(:series).and_return(series_info_without_environment)
      end

      it 'responds with both metrics missing requirements' do
        expect(subject.query).to eq([{ group: 'name', priority: 1, active_metrics: 0, metrics_missing_requirements: 2 }])
      end
    end

    context 'no series information found about the metrics' do
      before do
        allow(client).to receive(:series).and_return(empty_series_info)
      end

      it 'responds with both metrics missing requirements' do
        expect(subject.query).to eq([{ group: 'name', priority: 1, active_metrics: 0, metrics_missing_requirements: 2 }])
      end
    end

    context 'one of the series info was not found' do
      before do
        allow(client).to receive(:series).and_return(partialy_empty_series_info)
      end
      it 'responds with one active and one missing metric' do
        expect(subject.query).to eq([{ group: 'name', priority: 1, active_metrics: 1, metrics_missing_requirements: 1 }])
      end
    end
  end

  context 'with one group where only one metric is found' do
    before do
      allow(metric_group_class).to receive(:common_metrics).and_return([simple_metric_group])
      allow(client).to receive(:label_values).and_return('metric_a')
    end

    context 'both metrics in the group pass requirements' do
      before do
        allow(client).to receive(:series).and_return(series_info_with_environment)
      end

      it 'responds with one metrics as active and no missing requiremens' do
        expect(subject.query).to eq([{ group: 'name', priority: 1, active_metrics: 1, metrics_missing_requirements: 0 }])
      end
    end

    context 'no metrics in group pass requirements' do
      before do
        allow(client).to receive(:series).and_return(series_info_without_environment)
      end

      it 'responds with one metrics as active and no missing requiremens' do
        expect(subject.query).to eq([{ group: 'name', priority: 1, active_metrics: 0, metrics_missing_requirements: 1 }])
      end
    end
  end

  context 'with two groups where metrics are found in each group' do
    let(:second_metric_group) { simple_metric_group(name: 'nameb', metrics: simple_metrics(added_metric_name: 'metric_c')) }

    before do
      allow(metric_group_class).to receive(:common_metrics).and_return([simple_metric_group, second_metric_group])
      allow(client).to receive(:label_values).and_return('metric_c')
    end

    context 'all metrics in both groups pass requirements' do
      before do
        allow(client).to receive(:series).and_return(series_info_with_environment('metric_c'))
      end

      it 'responds with one metrics as active and no missing requiremens' do
        expect(subject.query).to eq([
                                      { group: 'name', priority: 1, active_metrics: 1, metrics_missing_requirements: 0 },
                                      { group: 'nameb', priority: 1, active_metrics: 2, metrics_missing_requirements: 0 }
                                    ]
                                   )
      end
    end

    context 'no metrics in groups pass requirements' do
      before do
        allow(client).to receive(:series).and_return(series_info_without_environment)
      end

      it 'responds with one metrics as active and no missing requiremens' do
        expect(subject.query).to eq([
                                      { group: 'name', priority: 1, active_metrics: 0, metrics_missing_requirements: 1 },
                                      { group: 'nameb', priority: 1, active_metrics: 0, metrics_missing_requirements: 2 }
                                    ]
                                   )
      end
    end
  end
end
