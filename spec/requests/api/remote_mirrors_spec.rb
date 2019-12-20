# frozen_string_literal: true

require 'spec_helper'

describe API::RemoteMirrors do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository, :remote_mirror) }

  describe 'GET /projects/:id/remote_mirrors' do
    let(:route) { "/projects/#{project.id}/remote_mirrors" }

    it 'requires `admin_remote_mirror` permission' do
      project.add_developer(user)

      get api(route, user)

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    it 'returns a list of remote mirrors' do
      project.add_maintainer(user)

      get api(route, user)

      expect(response).to have_gitlab_http_status(:success)
      expect(response).to match_response_schema('remote_mirrors')
    end

    context 'with the `remote_mirrors_api` feature disabled' do
      before do
        stub_feature_flags(remote_mirrors_api: false)
      end

      it 'responds with `not_found`' do
        get api(route, user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
