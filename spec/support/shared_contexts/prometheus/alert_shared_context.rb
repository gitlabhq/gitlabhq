# frozen_string_literal: true

# These contexts expect a `project` to be defined.
# It is expected that these contexts are used to create an
# alert.
RSpec.shared_context 'self-managed prometheus alert attributes' do
  let_it_be(:environment) { create(:environment, project: project, name: 'production') }

  let(:starts_at) { '2018-03-12T09:06:00Z' }
  let(:title) { 'title' }
  let(:y_label) { 'y_label' }
  let(:query) { 'avg(metric) > 1.0' }

  let(:embed_content) do
    {
      panel_groups: [{
        panels: [{
          type: 'area-chart',
          title: title,
          y_label: y_label,
          metrics: [{ query_range: query }]
        }]
      }]
    }.to_json
  end

  let(:payload) do
    {
      'startsAt' => starts_at,
      'generatorURL' => "http://host?g0.expr=#{CGI.escape(query)}",
      'labels' => {
        'gitlab_environment_name' => 'production'
      },
      'annotations' => {
        'title' => title,
        'gitlab_y_label' => y_label
      }
    }
  end

  let(:dashboard_url_for_alert) do
    Gitlab::Routing.url_helpers.metrics_dashboard_project_environment_url(
      project,
      environment,
      embed_json: embed_content,
      embedded: true,
      end: '2018-03-12T09:36:00Z',
      start: '2018-03-12T08:36:00Z'
    )
  end
end

RSpec.shared_context 'gitlab-managed prometheus alert attributes' do
  let_it_be(:prometheus_alert) { create(:prometheus_alert, project: project) }
  let(:prometheus_metric_id) { prometheus_alert.prometheus_metric_id }

  let(:payload) do
    {
      'startsAt' => '2018-03-12T09:06:00Z',
      'labels' => {
        'gitlab_alert_id' => prometheus_metric_id
      }
    }
  end

  let(:dashboard_url_for_alert) do
    Gitlab::Routing.url_helpers.metrics_dashboard_project_prometheus_alert_url(
      project,
      prometheus_metric_id,
      environment_id: prometheus_alert.environment_id,
      embedded: true,
      end: '2018-03-12T09:36:00Z',
      start: '2018-03-12T08:36:00Z'
    )
  end
end
