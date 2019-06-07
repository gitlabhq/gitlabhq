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
      allow(PrometheusMetric).to receive(:find_by_identifier).and_return(create(:prometheus_metric, query: prometheus_istio_query('test-name', 'test-ns')))
      allow(client).to receive(:query_range)
    end

    it 'has the query, but no data' do
      results = subject.query(serverless_func.id)

      expect(results.queries[0][:query_range]).to eql('floor(sum(rate(istio_revision_request_count{destination_configuration="test-name", destination_namespace="test-ns"}[1m])*30))')
    end
  end
end
