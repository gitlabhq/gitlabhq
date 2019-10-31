# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Metrics::Dashboard::Url do
  shared_examples_for 'a regex which matches the expected url' do
    it { is_expected.to be_a Regexp }

    it 'matches a metrics dashboard link with named params' do
      expect(subject).to match url

      subject.match(url) do |m|
        expect(m.named_captures).to eq expected_params
      end
    end
  end

  shared_examples_for 'does not match non-matching urls' do
    it 'does not match other gitlab urls that contain the term metrics' do
      url = Gitlab::Routing.url_helpers.active_common_namespace_project_prometheus_metrics_url('foo', 'bar', :json)

      expect(subject).not_to match url
    end

    it 'does not match other gitlab urls' do
      url = Gitlab.config.gitlab.url

      expect(subject).not_to match url
    end

    it 'does not match non-gitlab urls' do
      url = 'https://www.super_awesome_site.com/'

      expect(subject).not_to match url
    end
  end

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

    subject { described_class.regex }

    it_behaves_like 'a regex which matches the expected url'
    it_behaves_like 'does not match non-matching urls'
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

    it_behaves_like 'a regex which matches the expected url'
    it_behaves_like 'does not match non-matching urls'
  end

  describe '#build_dashboard_url' do
    it 'builds the url for the dashboard endpoint' do
      url = described_class.build_dashboard_url('foo', 'bar', 1)

      expect(url).to match described_class.regex
    end
  end
end
