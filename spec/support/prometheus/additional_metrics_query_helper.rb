module Prometheus
  module AdditionalMetricsQueryHelper
    def metric_names
      %w{metric_a metric_b}
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
