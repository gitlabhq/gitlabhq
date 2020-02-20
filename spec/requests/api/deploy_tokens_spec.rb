# frozen_string_literal: true

require 'spec_helper'

describe API::DeployTokens do
  let(:creator)       { create(:user) }
  let(:project)       { create(:project, creator_id: creator.id) }
  let!(:deploy_token) { create(:deploy_token, projects: [project]) }

  describe 'GET /deploy_tokens' do
    subject { get api('/deploy_tokens', user) }

    context 'when unauthenticated' do
      let(:user) { nil }

      it 'rejects the response as unauthorized' do
        subject

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when authenticated as non-admin user' do
      let(:user) { creator }

      it 'rejects the response as forbidden' do
        subject

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when authenticated as admin' do
      let(:user) { create(:admin) }

      it 'returns all deploy tokens' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.first['id']).to eq(deploy_token.id)
      end
    end
  end
end
