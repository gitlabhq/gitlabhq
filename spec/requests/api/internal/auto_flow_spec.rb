# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Internal::AutoFlow, feature_category: :deployment_management do
  let(:jwt_auth_headers) do
    jwt_token = JWT.encode(
      { 'iss' => Gitlab::Kas::JWT_ISSUER, 'aud' => Gitlab::Kas::JWT_AUDIENCE },
      Gitlab::Kas.secret,
      'HS256'
    )

    { Gitlab::Kas::INTERNAL_API_KAS_REQUEST_HEADER => jwt_token }
  end

  let(:jwt_secret) { SecureRandom.random_bytes(Gitlab::Kas::SECRET_LENGTH) }

  before do
    allow(Gitlab::Kas).to receive(:secret).and_return(jwt_secret)
  end

  shared_examples 'authorization' do
    context 'when not authenticated' do
      it 'returns 401' do
        send_request(headers: { Gitlab::Kas::INTERNAL_API_KAS_REQUEST_HEADER => '' })

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  describe 'GET /internal/autoflow/repository_info' do
    def send_request(headers: {}, params: {})
      get api('/internal/autoflow/repository_info'), params: params, headers: headers.reverse_merge(jwt_auth_headers)
    end

    def expect_success_response
      expect(response).to have_gitlab_http_status(:success)

      expect(json_response).to match(
        a_hash_including(
          'project_id' => project.id,
          'gitaly_info' => a_hash_including(
            'address' => match(/\.socket$/),
            'token' => 'secret'
          ),
          'gitaly_repository' => a_hash_including(
            'storage_name' => project.repository_storage,
            'relative_path' => "#{project.disk_path}.git",
            'gl_repository' => "project-#{project.id}",
            'gl_project_path' => project.full_path
          ),
          'default_branch' => project.default_branch_or_main
        )
      )
    end

    include_examples 'authorization'

    context 'when project exists' do
      let_it_be(:project) { create(:project) }

      it 'returns expected data for numerical project id', :aggregate_failures do
        send_request(params: { id: project.id })

        expect_success_response
      end

      it 'returns expected data for project full path', :aggregate_failures do
        send_request(params: { id: project.full_path })

        expect_success_response
      end
    end

    context 'when project does not exists' do
      it 'returns expected data', :aggregate_failures do
        send_request(params: { id: non_existing_record_id })

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
