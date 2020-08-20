# frozen_string_literal: true

RSpec.shared_examples_for 'metrics dashboard prometheus api proxy' do
  let(:service_params) { [proxyable, 'GET', 'query', expected_params] }
  let(:service_result) { { status: :success, body: prometheus_body } }
  let(:prometheus_proxy_service) { instance_double(Prometheus::ProxyService) }
  let(:proxyable_params) do
    {
      id: proxyable.id.to_s
    }
  end

  let(:expected_params) do
    ActionController::Parameters.new(
      prometheus_proxy_params(
        proxy_path: 'query',
        controller: described_class.controller_path,
        action: 'prometheus_proxy'
      )
    ).permit!
  end

  before do
    allow_next_instance_of(Prometheus::ProxyService, *service_params) do |proxy_service|
      allow(proxy_service).to receive(:execute).and_return(service_result)
    end
  end

  context 'with valid requests' do
    context 'with success result' do
      let(:prometheus_body) { '{"status":"success"}' }
      let(:prometheus_json_body) { Gitlab::Json.parse(prometheus_body) }

      it 'returns prometheus response' do
        get :prometheus_proxy, params: prometheus_proxy_params

        expect(Prometheus::ProxyService).to have_received(:new).with(*service_params)
        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to eq(prometheus_json_body)
      end

      context 'with nil query' do
        let(:params_without_query) do
          prometheus_proxy_params.except(:query)
        end

        before do
          expected_params.delete(:query)
        end

        it 'does not raise error' do
          get :prometheus_proxy, params: params_without_query

          expect(Prometheus::ProxyService).to have_received(:new).with(*service_params)
        end
      end
    end

    context 'with nil result' do
      let(:service_result) { nil }

      it 'returns 204 no_content' do
        get :prometheus_proxy, params: prometheus_proxy_params

        expect(json_response['status']).to eq(_('processing'))
        expect(json_response['message']).to eq(_('Not ready yet. Try again later.'))
        expect(response).to have_gitlab_http_status(:no_content)
      end
    end

    context 'with 404 result' do
      let(:service_result) { { http_status: 404, status: :success, body: '{"body": "value"}' } }

      it 'returns body' do
        get :prometheus_proxy, params: prometheus_proxy_params

        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response['body']).to eq('value')
      end
    end

    context 'with error result' do
      context 'with http_status' do
        let(:service_result) do
          { http_status: :service_unavailable, status: :error, message: 'error message' }
        end

        it 'sets the http response status code' do
          get :prometheus_proxy, params: prometheus_proxy_params

          expect(response).to have_gitlab_http_status(:service_unavailable)
          expect(json_response['status']).to eq('error')
          expect(json_response['message']).to eq('error message')
        end
      end

      context 'without http_status' do
        let(:service_result) { { status: :error, message: 'error message' } }

        it 'returns bad_request' do
          get :prometheus_proxy, params: prometheus_proxy_params

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['status']).to eq('error')
          expect(json_response['message']).to eq('error message')
        end
      end
    end
  end

  context 'with inappropriate requests' do
    let(:prometheus_body) { nil }

    context 'without correct permissions' do
      let(:user2) { create(:user) }

      before do
        sign_out(user)
        sign_in(user2)
      end

      it 'returns 404' do
        get :prometheus_proxy, params: prometheus_proxy_params

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  context 'with invalid proxyable id' do
    let(:prometheus_body) { nil }

    it 'returns 404' do
      get :prometheus_proxy, params: prometheus_proxy_params(id: proxyable.id + 1)

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  private

  def prometheus_proxy_params(params = {})
    {
      proxy_path: 'query',
      query: '1'
    }.merge(proxyable_params).merge(params)
  end
end
