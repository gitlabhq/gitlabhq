# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Internal::ErrorTracking, feature_category: :observability do
  let(:secret_token) { Gitlab::CurrentSettings.error_tracking_access_token }
  let(:headers) do
    { ::API::Internal::ErrorTracking::GITLAB_ERROR_TRACKING_TOKEN_HEADER => secret_token }
  end

  describe 'GET /internal/error_tracking/allowed' do
    let_it_be(:project) { create(:project) }

    let(:params) { { project_id: project.id, public_key: 'key' } }

    subject(:send_request) do
      post api('/internal/error_tracking/allowed'), params: params, headers: headers
    end

    before do
      # Because the feature flag is disabled in specs we have to enable it explicitly.
      stub_feature_flags(gitlab_error_tracking: true)
    end

    context 'when the secret header is missing' do
      let(:headers) { {} }

      it 'responds with unauthorized entity' do
        send_request

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when some params are missing' do
      let(:params) { { project_id: project.id } }

      it 'responds with unprocessable entity' do
        send_request

        expect(response).to have_gitlab_http_status(:unprocessable_entity)
      end
    end

    context 'when public_key is unknown' do
      it 'returns enabled: false' do
        send_request

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to eq('enabled' => false)
      end
    end

    context 'when unknown project_id is unknown' do
      it 'responds with 404 not found' do
        params[:project_id] = non_existing_record_id

        send_request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when the error tracking is disabled' do
      it 'returns enabled: false' do
        create(:error_tracking_client_key, :disabled, project: project)

        send_request

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to eq('enabled' => false)
      end
    end

    context 'when the error tracking is enabled' do
      let_it_be(:client_key) { create(:error_tracking_client_key, project: project) }

      before do
        params[:public_key] = client_key.public_key

        stub_application_setting(error_tracking_enabled: true)
        stub_application_setting(error_tracking_api_url: 'https://localhost/error_tracking')
      end

      it 'returns enabled: true' do
        send_request

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to eq('enabled' => true)
      end

      context 'when feature flags gitlab_error_tracking are disabled' do
        before do
          stub_feature_flags(gitlab_error_tracking: false)
        end

        it 'returns enabled: false' do
          send_request

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to eq('enabled' => false)
        end
      end
    end
  end
end
