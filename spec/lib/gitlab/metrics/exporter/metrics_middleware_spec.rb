# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::Exporter::MetricsMiddleware do
  let(:app) { double(:app) }
  let(:pid) { 'fake_exporter' }
  let(:env) { { 'PATH_INFO' => '/path', 'REQUEST_METHOD' => 'GET' } }

  subject(:middleware) { described_class.new(app, pid) }

  def metric(name, method, path, status)
    metric = ::Prometheus::Client.registry.get(name)
    return unless metric

    values = metric.values.transform_keys { |k| k.slice(:method, :path, :pid, :code) }
    values[{ method: method, path: path, pid: pid, code: status.to_s }]&.get
  end

  before do
    expect(app).to receive(:call).with(env).and_return([200, {}, []])
  end

  describe '#call', :prometheus do
    it 'records a total requests metric' do
      response = middleware.call(env)

      expect(response).to eq([200, {}, []])
      expect(metric(:exporter_http_requests_total, 'get', '/path', 200)).to eq(1.0)
    end

    it 'records a request duration histogram' do
      response = middleware.call(env)

      expect(response).to eq([200, {}, []])
      expect(metric(:exporter_http_request_duration_seconds, 'get', '/path', 200)).to be_a(Hash)
    end
  end
end
