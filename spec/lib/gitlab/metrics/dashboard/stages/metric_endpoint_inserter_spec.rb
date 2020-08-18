# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::Dashboard::Stages::MetricEndpointInserter do
  include MetricsDashboardHelpers

  let(:project) { build_stubbed(:project) }
  let(:environment) { build_stubbed(:environment, project: project) }

  describe '#transform!' do
    subject(:transform!) { described_class.new(project, dashboard, environment: environment).transform! }

    let(:dashboard) { load_sample_dashboard.deep_symbolize_keys }

    it 'generates prometheus_endpoint_path without newlines' do
      query = 'avg( sum( container_memory_usage_bytes{ container_name!="POD", '\
      'pod_name=~"^{{ci_environment_slug}}-(.*)", namespace="{{kube_namespace}}" } ) '\
      'by (job) ) without (job) /1024/1024/1024'

      transform!

      expect(all_metrics[2][:prometheus_endpoint_path]).to eq(prometheus_path(query))
    end

    it 'includes a path for the prometheus endpoint with each metric' do
      transform!

      expect(all_metrics).to satisfy_all do |metric|
        metric[:prometheus_endpoint_path].present? && !metric[:prometheus_endpoint_path].include?("\n")
      end
    end

    it 'works when query/query_range is a number' do
      query = 2000

      transform!

      expect(all_metrics[1][:prometheus_endpoint_path]).to eq(prometheus_path(query))
    end
  end

  private

  def all_metrics
    dashboard[:panel_groups].flat_map do |group|
      group[:panels].flat_map { |panel| panel[:metrics] }
    end
  end

  def prometheus_path(query)
    Gitlab::Routing.url_helpers.prometheus_api_project_environment_path(
      project,
      environment,
      proxy_path: :query_range,
      query: query
    )
  end
end
