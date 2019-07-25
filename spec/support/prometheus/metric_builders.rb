# frozen_string_literal: true

module Prometheus
  module MetricBuilders
    def simple_query(suffix = 'a', **opts)
      { query_range: "query_range_#{suffix}" }.merge(opts)
    end

    def simple_queries
      [simple_query, simple_query('b', label: 'label', unit: 'unit')]
    end

    def simple_metric(title: 'title', required_metrics: [], queries: [simple_query])
      Gitlab::Prometheus::Metric.new(title: title, required_metrics: required_metrics, weight: 1, queries: queries)
    end

    def simple_metrics(added_metric_name: 'metric_a')
      [
        simple_metric(required_metrics: %W(#{added_metric_name} metric_b), queries: simple_queries),
        simple_metric(required_metrics: [added_metric_name], queries: [simple_query('empty')]),
        simple_metric(required_metrics: %w{metric_c})
      ]
    end

    def simple_metric_group(name: 'name', metrics: simple_metrics)
      Gitlab::Prometheus::MetricGroup.new(name: name, priority: 1, metrics: metrics)
    end
  end
end
