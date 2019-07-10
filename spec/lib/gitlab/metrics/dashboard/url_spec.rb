# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Metrics::Dashboard::Url do
  describe '#regex' do
    it 'returns a regular expression' do
      expect(described_class.regex).to be_a Regexp
    end

    it 'matches a metrics dashboard link with named params' do
      url = Gitlab::Routing.url_helpers.metrics_namespace_project_environment_url('foo', 'bar', 1, start: 123345456, anchor: 'title')

      expected_params = {
        'url' => url,
        'namespace' => 'foo',
        'project' => 'bar',
        'environment' => '1',
        'query' => '?start=123345456',
        'anchor' => '#title'
      }

      expect(described_class.regex).to match url

      described_class.regex.match(url) do |m|
        expect(m.named_captures).to eq expected_params
      end
    end

    it 'does not match other gitlab urls that contain the term metrics' do
      url = Gitlab::Routing.url_helpers.active_common_namespace_project_prometheus_metrics_url('foo', 'bar', :json)

      expect(described_class.regex).not_to match url
    end

    it 'does not match other gitlab urls' do
      url = Gitlab.config.gitlab.url

      expect(described_class.regex).not_to match url
    end

    it 'does not match non-gitlab urls' do
      url = 'https://www.super_awesome_site.com/'

      expect(described_class.regex).not_to match url
    end
  end

  describe '#build_dashboard_url' do
    it 'builds the url for the dashboard endpoint' do
      url = described_class.build_dashboard_url('foo', 'bar', 1)

      expect(url).to match described_class.regex
    end
  end
end
