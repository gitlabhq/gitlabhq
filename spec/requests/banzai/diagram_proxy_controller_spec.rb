# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::DiagramProxyController, feature_category: :markdown do
  def decode_send_data(response)
    command, encoded_params = response.headers[Gitlab::Workhorse::SEND_DATA_HEADER].split(':')
    params = Gitlab::Json.safe_parse(Base64.urlsafe_decode64(encoded_params))
    [command, params]
  end

  let_it_be(:user) { create(:user) }

  let(:diagram_type) { 'plantuml' }
  let(:diagram_source) { 'Bob -> Sara : Hello' }
  let(:stored_data) { { user_id: user.id, diagram_type: diagram_type, diagram_source: diagram_source } }
  let(:key) { Banzai::Filter::DiagramProxyPostFilter.store(stored_data) }

  before do
    stub_application_setting(
      plantuml_enabled: true,
      plantuml_url: 'http://localhost:8080',
      plantuml_diagram_proxy_enabled: true,
      kroki_enabled: true,
      kroki_url: 'http://localhost:8000',
      kroki_diagram_proxy_enabled: true)
  end

  describe 'GET /-/diagram-proxy/:key' do
    subject(:request) { get "/-/diagram-proxy/#{key}" }

    context 'with a valid plantuml key and matching user' do
      before do
        sign_in(user)
      end

      it 'responds with workhorse send-url for plantuml' do
        request

        expect(response).to have_gitlab_http_status(:ok)

        command, params = decode_send_data(response)

        expect(command).to eq('send-url')
        expect(params['URL']).to include('localhost:8080')
        expect(params['SSRFFilter']).to be(true)
        expect(params['AllowedEndpoints']).to eq([])
      end
    end

    context 'with a valid kroki key and matching user' do
      let(:diagram_type) { 'graphviz' }
      let(:diagram_source) { 'digraph { a -> b }' }

      before do
        sign_in(user)
      end

      it 'responds with workhorse send-url for kroki' do
        request

        expect(response).to have_gitlab_http_status(:ok)

        command, params = decode_send_data(response)

        expect(command).to eq('send-url')
        expect(params['URL']).to include('localhost:8000')
        expect(params['SSRFFilter']).to be(true)
        expect(params['AllowedEndpoints']).to eq([])
      end
    end

    context 'when no key parameter is provided' do
      let(:key) { '' }

      before do
        sign_in(user)
      end

      it 'returns 404' do
        request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when the Redis key does not exist' do
      let(:key) { 'nonexistent-key' }

      before do
        sign_in(user)
      end

      it 'returns 404' do
        request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when the Redis key has already been used' do
      before do
        sign_in(user)
      end

      it 'returns 404 on the second request' do
        get "/-/diagram-proxy/#{key}"

        expect(response).to have_gitlab_http_status(:ok)

        get "/-/diagram-proxy/#{key}"

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when the Redis key has expired' do
      before do
        sign_in(user)
        key # force store
        Gitlab::Redis::Cache.with { |redis| redis.del("diagram_proxy:#{key}") }
      end

      it 'returns 404' do
        request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when the user does not match' do
      let_it_be(:other_user) { create(:user) }

      before do
        sign_in(other_user)
      end

      it 'returns 404' do
        request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when no user is signed in and key was stored with a user' do
      it 'returns 404' do
        request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when no user is signed in and key was stored without a user' do
      let(:stored_data) { { user_id: nil, diagram_type: diagram_type, diagram_source: diagram_source } }

      it 'responds successfully' do
        request

        expect(response).to have_gitlab_http_status(:ok)

        command, _params = decode_send_data(response)

        expect(command).to eq('send-url')
      end
    end

    context 'when outbound local requests allowlist is configured' do
      let(:diagram_type) { 'graphviz' }
      let(:diagram_source) { 'digraph { a -> b }' }

      before do
        sign_in(user)
        stub_application_setting(outbound_local_requests_whitelist: ['10.88.0.3', 'kroki.internal'])
      end

      it 'forwards the allowlist as AllowedEndpoints' do
        request

        expect(response).to have_gitlab_http_status(:ok)

        _command, params = decode_send_data(response)

        expect(params['AllowedEndpoints']).to contain_exactly('10.88.0.3', 'kroki.internal')
      end
    end

    context 'when plantuml proxy is disabled' do
      before do
        stub_application_setting(plantuml_diagram_proxy_enabled: false)
        sign_in(user)
      end

      it 'returns 404' do
        request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when kroki proxy is disabled' do
      let(:diagram_type) { 'graphviz' }
      let(:diagram_source) { 'digraph { a -> b }' }

      before do
        stub_application_setting(kroki_diagram_proxy_enabled: false)
        sign_in(user)
      end

      it 'returns 404' do
        request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
