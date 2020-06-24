# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Middleware::BasicHealthCheck do
  let(:app) { double(:app) }
  let(:middleware) { described_class.new(app) }
  let(:env) { {} }

  describe '#call' do
    context 'outside IP' do
      before do
        env['REMOTE_ADDR'] = '8.8.8.8'
      end

      it 'returns a 404' do
        env['PATH_INFO'] = described_class::HEALTH_PATH

        response = middleware.call(env)

        expect(response[0]).to eq(404)
      end

      it 'forwards the call for other paths' do
        env['PATH_INFO'] = '/'

        expect(app).to receive(:call)

        middleware.call(env)
      end
    end

    context 'with X-Forwarded-For headers' do
      let(:load_balancer_ip) { '1.2.3.4' }

      before do
        env['HTTP_X_FORWARDED_FOR'] = "#{load_balancer_ip}, 127.0.0.1"
        env['REMOTE_ADDR'] = '127.0.0.1'
        env['PATH_INFO'] = described_class::HEALTH_PATH
      end

      it 'returns 200 response when endpoint is allowed' do
        allow(Settings.monitoring).to receive(:ip_whitelist).and_return([load_balancer_ip])
        expect(app).not_to receive(:call)

        response = middleware.call(env)

        expect(response[0]).to eq(200)
        expect(response[1]).to eq({ 'Content-Type' => 'text/plain' })
        expect(response[2]).to eq(['GitLab OK'])
      end

      it 'returns 404 when whitelist is not configured' do
        allow(Settings.monitoring).to receive(:ip_whitelist).and_return([])

        response = middleware.call(env)

        expect(response[0]).to eq(404)
      end
    end

    context 'whitelisted IP' do
      before do
        env['REMOTE_ADDR'] = '127.0.0.1'
      end

      it 'returns 200 response when endpoint is hit' do
        env['PATH_INFO'] = described_class::HEALTH_PATH

        expect(app).not_to receive(:call)

        response = middleware.call(env)

        expect(response[0]).to eq(200)
        expect(response[1]).to eq({ 'Content-Type' => 'text/plain' })
        expect(response[2]).to eq(['GitLab OK'])
      end

      it 'forwards the call for other paths' do
        env['PATH_INFO'] = '/-/readiness'

        expect(app).to receive(:call)

        middleware.call(env)
      end
    end
  end
end
