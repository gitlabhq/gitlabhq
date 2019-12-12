# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Prometheus::Queries::KnativeInvocationQuery do
  include PrometheusHelpers

  let(:project) { create(:project) }
  let(:serverless_func) { Serverless::Function.new(project, 'test-name', 'test-ns') }
  let(:client) { double('prometheus_client') }

  subject { described_class.new(client) }

  context 'verify queries' do
    before do
      create(:prometheus_metric,
             :common,
             identifier: :system_metrics_knative_function_invocation_count,
             query: 'sum(ceil(rate(istio_requests_total{destination_service_namespace="%{kube_namespace}", destination_app=~"%{function_name}.*"}[1m])*60))')
    end

    it 'has the query, but no data' do
      expect(client).to receive(:query_range).with(
        'sum(ceil(rate(istio_requests_total{destination_service_namespace="test-ns", destination_app=~"test-name.*"}[1m])*60))',
        hash_including(:start, :stop)
      )

      subject.query(serverless_func.id)
    end
  end
end
