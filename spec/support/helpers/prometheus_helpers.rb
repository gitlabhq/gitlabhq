# frozen_string_literal: true

module PrometheusHelpers
  def prometheus_memory_query(environment_slug)
    %{avg(container_memory_usage_bytes{container_name!="POD",environment="#{environment_slug}"}) / 2^20}
  end

  def prometheus_cpu_query(environment_slug)
    %{avg(rate(container_cpu_usage_seconds_total{container_name!="POD",environment="#{environment_slug}"}[2m])) * 100}
  end

  def prometheus_istio_query(function_name, kube_namespace)
    %{floor(sum(rate(istio_revision_request_count{destination_configuration=\"#{function_name}\", destination_namespace=\"#{kube_namespace}\"}[1m])*30))}
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

  def prometheus_query_range_url(prometheus_query, start_time: 8.hours.ago, end_time: Time.now, step: nil)
    start_time = start_time.to_f
    end_time = end_time.to_f
    step ||= Gitlab::PrometheusClient.compute_step(start_time, end_time)

    query = {
      query: prometheus_query,
      start: start_time,
      end: end_time,
      step: step
    }.to_query

    "https://prometheus.example.com/api/v1/query_range?#{query}"
  end

  def prometheus_label_values_url(name)
    "https://prometheus.example.com/api/v1/label/#{name}/values"
  end

  def prometheus_series_url(*matches, start_time: 8.hours.ago, end_time: Time.now)
    query = {
      match: matches,
      start: start_time.to_f,
      end: end_time.to_f
    }.to_query
    "https://prometheus.example.com/api/v1/series?#{query}"
  end

  def stub_prometheus_request(url, body: {}, status: 200, headers: {})
    WebMock.stub_request(:get, url)
      .to_return({
        status: status,
        headers: { 'Content-Type' => 'application/json' }.merge(headers),
        body: body.to_json
      })
  end

  def stub_prometheus_query_error(url, error_message = 'error', body: {}, headers: {})
    response = {
      status: 'error',
      errorType: 'bad_data',
      error: error_message
    }.merge(body)

    WebMock.stub_request(:get, url)
      .to_return({
        status: 400,
        headers: { 'Content-Type' => 'application/json' }.merge(headers),
        body: response.to_json
      })
  end

  def stub_prometheus_request_with_exception(url, exception_type)
    WebMock.stub_request(:get, url).to_raise(exception_type)
  end

  def stub_any_prometheus_request
    WebMock.stub_request(:any, /prometheus.example.com/)
  end

  def stub_any_prometheus_request_with_response(status: 200, headers: {}, body: nil)
    stub_any_prometheus_request.to_return({
      status: status,
      headers: { 'Content-Type' => 'application/json' }.merge(headers),
      body: body || prometheus_values_body.to_json
    })
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
      data: {
        memory_values: prometheus_values_body('matrix').dig(:data, :result),
        memory_current: prometheus_value_body('vector').dig(:data, :result),
        cpu_values: prometheus_values_body('matrix').dig(:data, :result),
        cpu_current: prometheus_value_body('vector').dig(:data, :result)
      },
      last_update: last_update
    }
  end

  def prometheus_metrics_data(last_update: Time.now.utc)
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
      status: "success",
      data: {
        resultType: type,
        result: []
      }
    }
  end

  def prometheus_value_body(type = 'vector')
    {
      status: "success",
      data: {
        resultType: type,
        result: [
          {
            metric: {},
            value: [
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
      status: "success",
      data: {
        resultType: type,
        result: [
          {
            metric: {},
            values: [
              [1488758662.506, "0.00002996364761904785"],
              [1488758722.506, "0.00003090239047619091"]
            ]
          }
        ]
      }
    }
  end

  def prometheus_label_values
    {
      status: 'success',
      data: %w[job_adds job_controller_rate_limiter_use job_depth job_queue_latency job_work_duration_sum up]
    }
  end

  def prometheus_series(name)
    {
      status: 'success',
      data: [
        {
          __name__: name,
          container_name: 'gitlab',
          environment: 'mattermost',
          id: '/docker/9953982f95cf5010dfc59d7864564d5f188aaecddeda343699783009f89db667',
          image: 'gitlab/gitlab-ce:8.15.4-ce.1',
          instance: 'minikube',
          job: 'kubernetes-nodes',
          name: 'k8s_gitlab.e6611886_mattermost-4210310111-77z8r_gitlab_2298ae6b-da24-11e6-baee-8e7f67d0eb3a_43536cb6',
          namespace: 'gitlab',
          pod_name: 'mattermost-4210310111-77z8r'
        },
        {
          __name__: name,
          id: '/docker',
          instance: 'minikube',
          job: 'kubernetes-nodes'
        }
      ]
    }
  end

  def prometheus_alert_payload(firing: [], resolved: [])
    status = firing.any? ? 'firing' : 'resolved'
    alerts = firing + resolved
    alert_name = alerts.first || ''

    alerts_map = \
      firing.map { |title| prometheus_map_alert_payload('firing', title) } +
      resolved.map { |title| prometheus_map_alert_payload('resolved', title) }

    # See https://prometheus.io/docs/alerting/configuration/#%3Cwebhook_config%3E
    {
      'version' => '4',
      'receiver' => 'gitlab',
      'status' => status,
      'alerts' => alerts_map,
      'groupLabels' => {
        'alertname' => alert_name
      },
      'commonLabels' => {
        'alertname' => alert_name
      },
      'commonAnnotations' => {},
      'externalURL' => '',
      'groupKey' => "{}:{alertname=\'#{alert_name}\'}"
    }
  end

  def prometheus_alert_payload_fingerprint(title)
    # timestamp is hard-coded in #prometheus_map_alert_payload
    # sample fingerprint format comes from AlertManagement::Payload::Prometheus
    fingerprint = ["2018-09-24T08:57:31.095725221Z", title].join('/')

    Gitlab::AlertManagement::Fingerprint.generate(fingerprint)
  end

  private

  def prometheus_map_alert_payload(status, title)
    {
      'status' => status,
      'labels' => {
        'alertname' => title
      },
      'annotations' => {},
      'startsAt' => '2018-09-24T08:57:31.095725221Z',
      'endsAt' => '0001-01-01T00:00:00Z',
      'generatorURL' => 'http://prometheus-prometheus-server-URL'
    }
  end
end
