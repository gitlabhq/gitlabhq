# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::Dashboard::Url do
  include Gitlab::Routing.url_helpers

  describe '#metrics_regex' do
    let(:environment_id) { 1 }
    let(:url_params) do
      [
        'foo',
        'bar',
        environment_id,
        {
          start: '2019-08-02T05:43:09.000Z',
          dashboard: 'config/prometheus/common_metrics.yml',
          group: 'awesome group',
          anchor: 'title'
        }
      ]
    end

    let(:expected_params) do
      {
        'url' => url,
        'namespace' => 'foo',
        'project' => 'bar',
        'environment' => '1',
        'query' => '?dashboard=config%2Fprometheus%2Fcommon_metrics.yml&group=awesome+group&start=2019-08-02T05%3A43%3A09.000Z',
        'anchor' => '#title'
      }
    end

    subject { described_class.metrics_regex }

    context 'for /-/environments/:environment_id/metrics route' do
      let(:url) { metrics_namespace_project_environment_url(*url_params) }

      it_behaves_like 'regex which matches url when expected'
    end

    context 'for /-/metrics?environment=:environment_id route' do
      let(:url) { namespace_project_metrics_dashboard_url(*url_params) }
      let(:url_params) do
        [
          'namespace1',
          'project1',
          {
            environment: environment_id,
            start: '2019-08-02T05:43:09.000Z',
            dashboard: 'config/prometheus/common_metrics.yml',
            group: 'awesome group',
            anchor: 'title'
          }
        ]
      end

      let(:expected_params) do
        {
          'url' => url,
          'namespace' => 'namespace1',
          'project' => 'project1',
          'environment' => "#{environment_id}",
          'query' => "?dashboard=config%2Fprometheus%2Fcommon_metrics.yml&environment=#{environment_id}&group=awesome+group&start=2019-08-02T05%3A43%3A09.000Z",
          'anchor' => '#title'
        }
      end

      it_behaves_like 'regex which matches url when expected'
    end

    context 'for metrics_dashboard route' do
      let(:url) { metrics_dashboard_namespace_project_environment_url(*url_params) }

      it_behaves_like 'regex which matches url when expected'
    end
  end

  describe '#clusters_regex' do
    let(:url) { Gitlab::Routing.url_helpers.namespace_project_cluster_url(*url_params) }
    let(:url_params) do
      [
        'foo',
        'bar',
        '1',
        {
          group: 'Cluster Health',
          title: 'Memory Usage',
          y_label: 'Memory 20(GiB)',
          anchor: 'title'
        }
      ]
    end

    let(:expected_params) do
      {
        'url' => url,
        'namespace' => 'foo',
        'project' => 'bar',
        'cluster_id' => '1',
        'query' => '?group=Cluster+Health&title=Memory+Usage&y_label=Memory+20%28GiB%29',
        'anchor' => '#title'
      }
    end

    subject { described_class.clusters_regex }

    it_behaves_like 'regex which matches url when expected'

    context 'for metrics_dashboard route' do
      let(:url) do
        metrics_dashboard_namespace_project_cluster_url(
          *url_params, cluster_type: :project, embedded: true, format: :json
        )
      end

      let(:expected_params) do
        {
          'url' => url,
          'namespace' => 'foo',
          'project' => 'bar',
          'cluster_id' => '1',
          'query' => '?cluster_type=project&embedded=true',
          'anchor' => nil
        }
      end

      it_behaves_like 'regex which matches url when expected'
    end
  end

  describe '#grafana_regex' do
    let(:url) do
      namespace_project_grafana_api_metrics_dashboard_url(
        'foo',
        'bar',
        start: '2019-08-02T05:43:09.000Z',
        dashboard: 'config/prometheus/common_metrics.yml',
        group: 'awesome group',
        anchor: 'title'
      )
    end

    let(:expected_params) do
      {
        'url' => url,
        'namespace' => 'foo',
        'project' => 'bar',
        'query' => '?dashboard=config%2Fprometheus%2Fcommon_metrics.yml&group=awesome+group&start=2019-08-02T05%3A43%3A09.000Z',
        'anchor' => '#title'
      }
    end

    subject { described_class.grafana_regex }

    it_behaves_like 'regex which matches url when expected'
  end

  describe '#alert_regex' do
    let(:url) { Gitlab::Routing.url_helpers.metrics_dashboard_namespace_project_prometheus_alert_url(*url_params) }
    let(:url_params) do
      [
        'foo',
        'bar',
        '1',
        {
          start: '2020-02-10T12:59:49.938Z',
          end: '2020-02-10T20:59:49.938Z',
          anchor: "anchor"
        }
      ]
    end

    let(:expected_params) do
      {
        'url' => url,
        'namespace' => 'foo',
        'project' => 'bar',
        'alert' => '1',
        'query' => "?end=2020-02-10T20%3A59%3A49.938Z&start=2020-02-10T12%3A59%3A49.938Z",
        'anchor' => '#anchor'
      }
    end

    subject { described_class.alert_regex }

    it_behaves_like 'regex which matches url when expected'

    it_behaves_like 'regex which matches url when expected' do
      let(:url) { Gitlab::Routing.url_helpers.metrics_dashboard_namespace_project_prometheus_alert_url(*url_params, format: :json) }

      let(:expected_params) do
        {
          'url' => url,
          'namespace' => 'foo',
          'project' => 'bar',
          'alert' => '1',
          'query' => nil,
          'anchor' => nil
        }
      end
    end
  end

  describe '#build_dashboard_url' do
    it 'builds the url for the dashboard endpoint' do
      url = described_class.build_dashboard_url('foo', 'bar', 1)

      expect(url).to match described_class.metrics_regex
    end
  end
end
