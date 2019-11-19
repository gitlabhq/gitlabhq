# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Metrics::Exporter::WebExporter do
  let(:exporter) { described_class.new }
  let(:readiness_probe) { exporter.send(:readiness_probe).execute }

  before do
    stub_config(
      monitoring: {
        web_exporter: {
          enabled: true,
          port: 0,
          address: '127.0.0.1'
        }
      }
    )

    exporter.start
  end

  after do
    exporter.stop
  end

  context 'when running server' do
    it 'readiness probe returns succesful status' do
      expect(readiness_probe.http_status).to eq(200)
      expect(readiness_probe.json).to include(status: 'ok')
      expect(readiness_probe.json).to include('web_exporter' => [{ 'status': 'ok' }])
    end
  end

  describe '#mark_as_not_running!' do
    it 'readiness probe returns a failure status' do
      exporter.mark_as_not_running!

      expect(readiness_probe.http_status).to eq(503)
      expect(readiness_probe.json).to include(status: 'failed')
      expect(readiness_probe.json).to include('web_exporter' => [{ 'status': 'failed' }])
    end
  end
end
