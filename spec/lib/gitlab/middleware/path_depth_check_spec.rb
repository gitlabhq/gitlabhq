# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Middleware::PathDepthCheck, feature_category: :cell do
  let(:fake_response) { [200, { 'Content-Type' => 'text/plain' }, ['OK']] }
  let(:app) { ->(_) { fake_response } }
  let(:middleware) { described_class.new(app) }
  let(:env) { Rack::MockRequest.env_for(path) }

  describe '#call' do
    context 'with empty path' do
      let(:path) { '' }

      it 'forwards the request to the app' do
        response = middleware.call(env)

        expect(response[0]).to eq(200)
      end
    end

    context 'with root path' do
      let(:path) { '/' }

      it 'forwards the request to the app' do
        response = middleware.call(env)

        expect(response[0]).to eq(200)
      end
    end

    context 'when path depth is at the limit' do
      let(:path) { '/a' * described_class::MAX_PATH_SEGMENTS }

      it 'forwards the request to the app' do
        response = middleware.call(env)

        expect(response[0]).to eq(200)
      end
    end

    context 'when path depth exceeds limit' do
      let(:path) { '/a' * (described_class::MAX_PATH_SEGMENTS + 1) }

      it 'returns 414 response' do
        response = middleware.call(env)

        expect(response).to eq(described_class::REJECTION_RESPONSE)
        expect(response[0]).to eq(414)
      end

      it 'logs the rejection' do
        expect(Gitlab::AppLogger).to receive(:warn).with(
          message: 'Path depth limit exceeded',
          class_name: described_class.name,
          path_segment_count: described_class::MAX_PATH_SEGMENTS + 1,
          remote_ip: env['REMOTE_ADDR']
        )

        middleware.call(env)
      end
    end

    context 'with deeply nested namespace path' do
      let(:path) { '/a/b/c/d/e/f/g/h/i/j/k/l/m/n/o/p/q/r/s/t/project/-/merge_requests/1/diffs' }

      it 'forwards the request to the app' do
        response = middleware.call(env)

        expect(response[0]).to eq(200)
      end
    end
  end
end
