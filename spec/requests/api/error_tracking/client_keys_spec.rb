# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ErrorTracking::ClientKeys, feature_category: :observability do
  let_it_be(:guest) { create(:user) }
  let_it_be(:maintainer) { create(:user) }
  let_it_be(:setting) { create(:project_error_tracking_setting) }
  let_it_be(:project) { setting.project }

  let!(:client_key) { create(:error_tracking_client_key, project: project) }

  before do
    project.add_guest(guest)
    project.add_maintainer(maintainer)
  end

  shared_examples 'endpoint with authorization' do
    context 'when unauthenticated' do
      let(:user) { nil }

      it { expect(response).to have_gitlab_http_status(:unauthorized) }
    end

    context 'when authenticated as non-maintainer' do
      let(:user) { guest }

      it { expect(response).to have_gitlab_http_status(:forbidden) }
    end
  end

  describe "GET /projects/:id/error_tracking/client_keys" do
    before do
      get api("/projects/#{project.id}/error_tracking/client_keys", user)
    end

    it_behaves_like 'endpoint with authorization'

    context 'when authenticated as maintainer' do
      let(:user) { maintainer }

      it 'returns client keys' do
        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response.size).to eq(1)
        expect(json_response.first['id']).to eq(client_key.id)
      end
    end
  end

  describe "POST /projects/:id/error_tracking/client_keys" do
    before do
      post api("/projects/#{project.id}/error_tracking/client_keys", user)
    end

    it_behaves_like 'endpoint with authorization'

    context 'when authenticated as maintainer' do
      let(:user) { maintainer }

      it 'returns a newly created client key' do
        new_key = project.error_tracking_client_keys.last

        expect(json_response['id']).to eq(new_key.id)
        expect(json_response['public_key']).to eq(new_key.public_key)
        expect(json_response['sentry_dsn']).to eq(new_key.sentry_dsn)
      end
    end
  end

  describe "DELETE /projects/:id/error_tracking/client_keys/:key_id" do
    before do
      delete api("/projects/#{project.id}/error_tracking/client_keys/#{client_key.id}", user)
    end

    it_behaves_like 'endpoint with authorization'

    context 'when authenticated as maintainer' do
      let(:user) { maintainer }

      it 'returns a correct status' do
        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'returns specific fields using the entity' do
        expect(json_response.keys).to match_array(%w[id active public_key sentry_dsn])
      end
    end
  end
end
