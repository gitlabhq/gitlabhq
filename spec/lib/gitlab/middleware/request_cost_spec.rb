# frozen_string_literal: true

require 'spec_helper'
require 'rack'

RSpec.describe Gitlab::Middleware::RequestCost, :request_store, feature_category: :rate_limiting do
  let(:app) { instance_double(Rack::Builder) }
  let(:middleware) { described_class.new(app) }
  let(:env) { {} }
  let(:status) { 200 }
  let(:headers) { {} }
  let(:body) { ['OK'] }

  before do
    allow(app).to receive(:call).with(env).and_return([status, headers, body])
    stub_feature_flags(request_cost_headers: true)
  end

  describe '#call' do
    context 'when the feature flag is disabled' do
      before do
        stub_feature_flags(request_cost_headers: false)
        Gitlab::RequestCost.current.add(5, resource: :gitaly)
        allow(Gitlab::ApplicationContext).to receive(:current_context_attribute)
          .with(:root_namespace).and_return('my-group')
      end

      it 'does not read cost or emit headers' do
        expect(Gitlab::RequestCost).not_to receive(:current)

        _status, result_headers, _body = middleware.call(env)

        expect(result_headers).not_to have_key('x-gitlab-score-gitaly')
        expect(result_headers).not_to have_key('x-gitlab-namespace')
      end
    end

    context 'when no Gitaly cost is present' do
      before do
        allow(Gitlab::ApplicationContext).to receive(:current_context_attribute)
          .with(:root_namespace).and_return('my-group')
      end

      it 'omits both score and namespace headers' do
        # Namespace is the bucketing characteristic for the score-based
        # Cloudflare rules.
        _status, result_headers, _body = middleware.call(env)

        expect(result_headers).not_to have_key('x-gitlab-score-gitaly')
        expect(result_headers).not_to have_key('x-gitlab-namespace')
      end
    end

    context 'with Gitaly cost' do
      before do
        Gitlab::RequestCost.current.add(3, resource: :gitaly)
        allow(Gitlab::ApplicationContext).to receive(:current_context_attribute)
          .with(:root_namespace).and_return('my-group')
      end

      it 'sets gitaly score and namespace headers' do
        _status, result_headers, _body = middleware.call(env)

        expect(result_headers['x-gitlab-score-gitaly']).to eq('3')
        expect(result_headers['x-gitlab-namespace']).to eq('my-group')
      end
    end

    context 'without a namespace' do
      before do
        Gitlab::RequestCost.current.add(2, resource: :gitaly)
        allow(Gitlab::ApplicationContext).to receive(:current_context_attribute)
          .with(:root_namespace).and_return(nil)
      end

      it 'omits both score and namespace headers' do
        # The score is only actionable when paired with a namespace bucket
        # for Cloudflare; emitting it alone would skew the no-bucket pool.
        _status, result_headers, _body = middleware.call(env)

        expect(result_headers).not_to have_key('x-gitlab-score-gitaly')
        expect(result_headers).not_to have_key('x-gitlab-namespace')
      end
    end

    context 'when response already has headers' do
      let(:headers) { { 'X-Custom' => 'value' } }

      before do
        Gitlab::RequestCost.current.add(1, resource: :gitaly)
        allow(Gitlab::ApplicationContext).to receive(:current_context_attribute)
          .with(:root_namespace).and_return('my-group')
      end

      it 'preserves existing headers' do
        _status, result_headers, _body = middleware.call(env)

        expect(result_headers['X-Custom']).to eq('value')
        expect(result_headers['x-gitlab-score-gitaly']).to eq('1')
        expect(result_headers['x-gitlab-namespace']).to eq('my-group')
      end
    end
  end
end
