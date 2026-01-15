# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Internal::Ci::JobRouter, feature_category: :continuous_integration do
  let_it_be(:runner) { create(:ci_runner, :instance) }

  let(:jwt_secret) { SecureRandom.random_bytes(Gitlab::Kas::SECRET_LENGTH) }
  let(:jwt_token) do
    JWT.encode(
      { 'iss' => Gitlab::Kas::JWT_ISSUER, 'aud' => Gitlab::Kas::JWT_AUDIENCE },
      jwt_secret,
      'HS256'
    )
  end

  let(:kas_headers) { { Gitlab::Kas::INTERNAL_API_KAS_REQUEST_HEADER => jwt_token } }

  before do
    allow(Gitlab::Kas).to receive_messages(enabled?: true, secret: jwt_secret)
  end

  describe 'GET /internal/ci/agents/runner/info' do
    subject(:request) { get api('/internal/ci/agents/runner/info'), headers: headers.reverse_merge(kas_headers) }

    context 'when not authenticated' do
      let(:headers) { { Gitlab::Kas::INTERNAL_API_KAS_REQUEST_HEADER => '' } }

      it 'returns 401' do
        request

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when no Gitlab-Agent-Api-Request header is sent' do
      let(:headers) { {} }

      it 'returns 401' do
        request

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when Gitlab-Agent-Api-Request header is for non-existent agent' do
      let(:headers) { { Gitlab::Kas::INTERNAL_API_AGENT_REQUEST_HEADER => 'NONEXISTENT' } }

      it 'returns 401' do
        request

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when a runner is found' do
      let(:headers) { { Gitlab::Kas::INTERNAL_API_AGENT_REQUEST_HEADER => runner.token } }

      it 'returns expected data' do
        request

        expect(response).to have_gitlab_http_status(:success)
        expect(json_response).to eq('runner_id' => runner.id)
      end
    end
  end
end
