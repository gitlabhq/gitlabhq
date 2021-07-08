# frozen_string_literal: true

module GrafanaApiHelpers
  def valid_grafana_dashboard_link(base_url)
    base_url +
      '/d/XDaNK6amz/gitlab-omnibus-redis' \
      '?from=1570397739557&to=1570484139557' \
      '&var-instance=localhost:9121&panelId=8'
  end

  def stub_dashboard_request(base_url, path: '/api/dashboards/uid/XDaNK6amz', body: nil)
    body ||= fixture_file('grafana/dashboard_response.json')

    stub_request(:get, "#{base_url}#{path}")
      .to_return(
        status: 200,
        body: body,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  def stub_datasource_request(base_url, path: '/api/datasources/name/GitLab%20Omnibus', body: nil)
    body ||= fixture_file('grafana/datasource_response.json')

    stub_request(:get, "#{base_url}#{path}")
      .to_return(
        status: 200,
        body: body,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  def stub_all_grafana_proxy_requests(base_url)
    stub_request(:any, %r{#{base_url}/api/datasources/proxy})
      .to_return(
        status: 200,
        body: fixture_file('grafana/proxy_response.json'),
        headers: { 'Content-Type' => 'application/json' }
      )
  end
end
