# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Metrics::Dashboard::Url do
  describe '#regex' do
    let(:url) do
      Gitlab::Routing.url_helpers.metrics_namespace_project_environment_url(
        'foo',
        'bar',
        1,
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
        'environment' => '1',
        'query' => '?dashboard=config%2Fprometheus%2Fcommon_metrics.yml&group=awesome+group&start=2019-08-02T05%3A43%3A09.000Z',
        'anchor' => '#title'
      }
    end

    subject { described_class.metrics_regex }

    it_behaves_like 'regex which matches url when expected'
  end

  describe '#grafana_regex' do
    let(:url) do
      Gitlab::Routing.url_helpers.namespace_project_grafana_api_metrics_dashboard_url(
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

  describe '#build_dashboard_url' do
    it 'builds the url for the dashboard endpoint' do
      url = described_class.build_dashboard_url('foo', 'bar', 1)

      expect(url).to match described_class.metrics_regex
    end
  end
end
