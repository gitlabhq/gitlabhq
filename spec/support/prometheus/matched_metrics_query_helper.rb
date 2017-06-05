module Prometheus
  module MatchedMetricsQueryHelper
    def metric_names
      %w{metric_a metric_b}
    end

    def simple_metrics(metric_name = 'metric_a')
      [Gitlab::Prometheus::Metric.new('title', %W(#{metric_name} metric_b), nil, nil),
       Gitlab::Prometheus::Metric.new('title', [metric_name], nil, nil)]
    end

    def simple_metric_group(name = 'name', metrics = simple_metrics)
      Gitlab::Prometheus::MetricGroup.new(name, 1, metrics)
    end

    def series_info_with_environment(*more_metrics)
      %w{metric_a metric_b}.concat(more_metrics).map { |metric_name| { '__name__' => metric_name, 'environment' => '' } }
    end

    def series_info_without_environment
      [{ '__name__' => 'metric_a' },
       { '__name__' => 'metric_b' }]
    end

    def partialy_empty_series_info
      [{ '__name__' => 'metric_a', 'environment' => '' }]
    end

    def empty_series_info
      []
    end
  end
end
