module PrometheusHelpers
  def prometheus_memory_query(environment_slug)
    %{avg(container_memory_usage_bytes{container_name!="POD",environment="#{environment_slug}"}) / 2^20}
  end

  def prometheus_cpu_query(environment_slug)
    %{avg(rate(container_cpu_usage_seconds_total{container_name!="POD",environment="#{environment_slug}"}[2m])) * 100}
  end

  def prometheus_ping_url(prometheus_query)
    query = { query: prometheus_query }.to_query

    "https://prometheus.example.com/api/v1/query?#{query}"
  end

  def prometheus_query_url(prometheus_query)
    query = { query: prometheus_query }.to_query

    "https://prometheus.example.com/api/v1/query?#{query}"
  end

  def prometheus_query_with_time_url(prometheus_query, time)
    query = { query: prometheus_query, time: time.to_f }.to_query

    "https://prometheus.example.com/api/v1/query?#{query}"
  end

  def prometheus_query_range_url(prometheus_query, start: 8.hours.ago, stop: Time.now.to_f)
    query = {
      query: prometheus_query,
      start: start.to_f,
      end: stop,
      step: 1.minute.to_i
    }.to_query

    "https://prometheus.example.com/api/v1/query_range?#{query}"
  end

  def stub_prometheus_request(url, body: {}, status: 200)
    WebMock.stub_request(:get, url)
      .to_return({
        status: status,
        headers: { 'Content-Type' => 'application/json' },
        body: body.to_json
      })
  end

  def stub_prometheus_request_with_exception(url, exception_type)
    WebMock.stub_request(:get, url).to_raise(exception_type)
  end

  def stub_all_prometheus_requests(environment_slug, body: nil, status: 200)
    stub_prometheus_request(
      prometheus_query_with_time_url(prometheus_memory_query(environment_slug), Time.now.utc),
      status: status,
      body: body || prometheus_value_body
    )
    stub_prometheus_request(
      prometheus_query_with_time_url(prometheus_memory_query(environment_slug), 8.hours.ago),
      status: status,
      body: body || prometheus_value_body
    )
    stub_prometheus_request(
      prometheus_query_range_url(prometheus_memory_query(environment_slug)),
      status: status,
      body: body || prometheus_values_body
    )
    stub_prometheus_request(
      prometheus_query_with_time_url(prometheus_cpu_query(environment_slug), Time.now.utc),
      status: status,
      body: body || prometheus_value_body
    )
    stub_prometheus_request(
      prometheus_query_with_time_url(prometheus_cpu_query(environment_slug), 8.hours.ago),
      status: status,
      body: body || prometheus_value_body
    )
    stub_prometheus_request(
      prometheus_query_range_url(prometheus_cpu_query(environment_slug)),
      status: status,
      body: body || prometheus_values_body
    )
  end

  def prometheus_data(last_update: Time.now.utc)
    {
      success: true,
      metrics: {
        memory_values: prometheus_values_body('matrix').dig(:data, :result),
        memory_current: prometheus_value_body('vector').dig(:data, :result),
        cpu_values: prometheus_values_body('matrix').dig(:data, :result),
        cpu_current: prometheus_value_body('vector').dig(:data, :result)
      },
      last_update: last_update
    }
  end

  def prometheus_empty_body(type)
    {
      "status": "success",
      "data": {
        "resultType": type,
        "result": []
      }
    }
  end

  def prometheus_value_body(type = 'vector')
    {
      "status": "success",
      "data": {
        "resultType": type,
        "result": [
          {
            "metric": {},
            "value": [
              1488772511.004,
              "0.000041021495238095323"
            ]
          }
        ]
      }
    }
  end

  def prometheus_values_body(type = 'matrix')
    {
      "status": "success",
      "data": {
        "resultType": type,
        "result": [
          {
            "metric": {},
            "values": [
              [1488758662.506, "0.00002996364761904785"],
              [1488758722.506, "0.00003090239047619091"]
            ]
          }
        ]
      }
    }
  end
end
