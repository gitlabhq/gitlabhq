# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Metrics::Exporter::WebExporter do
  let(:exporter) { described_class.new }

  context 'when blackout seconds is used' do
    let(:blackout_seconds) { 0 }
    let(:readiness_probe) { exporter.send(:readiness_probe).execute }

    before do
      stub_config(
        monitoring: {
          web_exporter: {
            enabled: true,
            port: 0,
            address: '127.0.0.1',
            blackout_seconds: blackout_seconds
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

    context 'when blackout seconds is 10s' do
      let(:blackout_seconds) { 10 }

      it 'readiness probe returns a failure status' do
        # during sleep we check the status of readiness probe
        expect(exporter).to receive(:sleep).with(10) do
          expect(readiness_probe.http_status).to eq(503)
          expect(readiness_probe.json).to include(status: 'failed')
          expect(readiness_probe.json).to include('web_exporter' => [{ 'status': 'failed' }])
        end

        exporter.stop
      end
    end

    context 'when blackout is disabled' do
      let(:blackout_seconds) { 0 }

      it 'readiness probe returns a failure status' do
        expect(exporter).not_to receive(:sleep)

        exporter.stop
      end
    end
  end
end
