module Prometheus
  module MetricBuilders
    def simple_query(suffix = 'a', **opts)
      { query_range: "query_range_#{suffix}" }.merge(opts)
    end

    def simple_queries
      [simple_query, simple_query('b', label: 'label', unit: 'unit')]
    end

    def simple_metric(title: 'title', required_metrics: [], queries: [simple_query])
      Gitlab::Prometheus::Metric.new(title, required_metrics, nil, nil, queries)
    end

    def simple_metrics
      [
        simple_metric(required_metrics: %w(metric_a metric_b), queries: simple_queries),
        simple_metric(required_metrics: %w{metric_a}, queries: [simple_query('empty')]),
        simple_metric(required_metrics: %w{metric_c})
      ]
    end

    def simple_metric_group(name: 'name', metrics: simple_metrics)
      Gitlab::Prometheus::MetricGroup.new(name, 1, metrics)
    end
  end
end
