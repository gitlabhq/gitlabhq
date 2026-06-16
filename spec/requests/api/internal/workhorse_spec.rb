# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Internal::Workhorse, :allow_forgery_protection, feature_category: :shared do
  include WorkhorseHelpers

  context '/authorize_upload' do
    let_it_be(:user, freeze: false) { create(:user) }

    let(:headers) { {} }

    subject { post(api('/internal/workhorse/authorize_upload'), headers: headers) }

    def expect_status(status)
      subject
      expect(response).to have_gitlab_http_status(status)
    end

    context 'without workhorse internal header' do
      it { expect_status(:forbidden) }
    end

    context 'with workhorse internal header' do
      let(:headers) { workhorse_internal_api_request_header }

      it { expect_status(:unauthorized) }

      context 'as a logged in user' do
        before do
          login_as(user)
        end

        it { expect_status(:success) }

        it 'returns the temp upload path' do
          subject
          expect(json_response['TempPath']).to eq(Rails.root.join('tmp/tests/public/uploads/tmp').to_s)
        end
      end
    end
  end

  context '/oauth_routing', feature_category: :system_access do
    let_it_be(:application) { create(:oauth_application) }
    let(:headers) { workhorse_internal_api_request_header }
    let(:params) { { client_id: application.uid } }

    subject(:perform_request) do
      post(api('/internal/workhorse/oauth_routing'), headers: headers, params: params)
    end

    context 'without workhorse internal header' do
      let(:headers) { {} }

      it 'returns 403 forbidden' do
        perform_request

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'with workhorse internal header' do
      it 'returns the workhorse vendor content type' do
        perform_request

        expect(response.media_type).to eq(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
      end

      context 'when the feature flag is enabled for the application' do
        before do
          stub_feature_flags(proxy_oauth_requests_to_iam_service: application)
        end

        it 'routes to IAM', :aggregate_failures do
          perform_request

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to eq('destination' => 'iam')
        end
      end

      context 'when the feature flag is disabled for the application' do
        before do
          stub_feature_flags(proxy_oauth_requests_to_iam_service: false)
        end

        it 'routes to Rails', :aggregate_failures do
          perform_request

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to eq('destination' => 'rails')
        end
      end

      context 'when the client_id does not match any application' do
        let(:params) { { client_id: 'nonexistent-client-id' } }

        it 'routes to Rails (documented fallback for unknown apps)', :aggregate_failures do
          perform_request

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to eq('destination' => 'rails')
        end
      end

      context 'when the client_id parameter is missing' do
        let(:params) { {} }

        it 'routes to Rails (documented fallback for missing client_id)', :aggregate_failures do
          perform_request

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to eq('destination' => 'rails')
        end
      end
    end
  end
end
