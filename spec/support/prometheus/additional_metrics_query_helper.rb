module Prometheus
  module AdditionalMetricsQueryHelper
    def metric_names
      %w{metric_a metric_b}
    end

    def simple_queries
      [{ query_range: 'query_range_a' }, { query_range: 'query_range_b', label: 'label', unit: 'unit' }]
    end

    def simple_query(suffix = 'a')
      [{ query_range: "query_range_#{suffix}" }]
    end

    def simple_metrics
      [
        Gitlab::Prometheus::Metric.new('title', %w(metric_a metric_b), nil, nil, simple_queries),
        Gitlab::Prometheus::Metric.new('title', %w{metric_a}, nil, nil, simple_query('empty')),
        Gitlab::Prometheus::Metric.new('title', %w{metric_c}, nil, nil)
      ]
    end

    def simple_metric_group(name = 'name', metrics = simple_metrics)
      Gitlab::Prometheus::MetricGroup.new(name, 1, metrics)
    end

    def query_result
      [
        {
          'metric': {},
          'value': [
            1488772511.004,
            '0.000041021495238095323'
          ]
        }
      ]
    end

    def query_range_result
      [
        {
          'metric': {},
          'values': [
            [1488758662.506, '0.00002996364761904785'],
            [1488758722.506, '0.00003090239047619091']
          ]
        }
      ]
    end
  end
end
