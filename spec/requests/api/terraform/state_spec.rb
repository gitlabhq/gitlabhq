# frozen_string_literal: true

require 'spec_helper'

describe API::Terraform::State do
  def auth_header_for(user)
    auth_header = ActionController::HttpAuthentication::Basic.encode_credentials(
      user.username,
      create(:personal_access_token, user: user).token
    )
    { 'HTTP_AUTHORIZATION' => auth_header }
  end

  let!(:project) { create(:project) }
  let(:developer) { create(:user) }
  let(:maintainer) { create(:user) }
  let(:state_name) { 'state' }

  before do
    project.add_maintainer(maintainer)
  end

  describe 'GET /projects/:id/terraform/state/:name' do
    it 'returns 401 if user is not authenticated' do
      headers = { 'HTTP_AUTHORIZATION' => 'failing_token' }
      get api("/projects/#{project.id}/terraform/state/#{state_name}"), headers: headers

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    it 'returns terraform state belonging to a project of given state name' do
      get api("/projects/#{project.id}/terraform/state/#{state_name}"), headers: auth_header_for(maintainer)

      expect(response).to have_gitlab_http_status(:not_implemented)
      expect(response.body).to eq('not implemented')
    end

    it 'returns not found if the project does not exists' do
      get api("/projects/0000/terraform/state/#{state_name}"), headers: auth_header_for(maintainer)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'returns forbidden if the user cannot access the state' do
      project.add_developer(developer)
      get api("/projects/#{project.id}/terraform/state/#{state_name}"), headers: auth_header_for(developer)

      expect(response).to have_gitlab_http_status(:forbidden)
    end
  end

  describe 'POST /projects/:id/terraform/state/:name' do
    context 'when terraform state with a given name is already present' do
      it 'updates the state' do
        post api("/projects/#{project.id}/terraform/state/#{state_name}"),
          params: '{ "instance": "example-instance" }',
          headers: { 'Content-Type' => 'text/plain' }.merge(auth_header_for(maintainer))

        expect(response).to have_gitlab_http_status(:not_implemented)
        expect(response.body).to eq('not implemented')
      end

      it 'returns forbidden if the user cannot access the state' do
        project.add_developer(developer)
        get api("/projects/#{project.id}/terraform/state/#{state_name}"), headers: auth_header_for(developer)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when there is no terraform state of a given name' do
      it 'creates a new state' do
        post api("/projects/#{project.id}/terraform/state/example2"),
          headers: auth_header_for(maintainer),
          params: '{ "database": "example-database" }'

        expect(response).to have_gitlab_http_status(:not_implemented)
        expect(response.body).to eq('not implemented')
      end
    end
  end

  describe 'DELETE /projects/:id/terraform/state/:name' do
    it 'deletes the state' do
      delete api("/projects/#{project.id}/terraform/state/#{state_name}"), headers: auth_header_for(maintainer)

      expect(response).to have_gitlab_http_status(:not_implemented)
    end

    it 'returns forbidden if the user cannot access the state' do
      project.add_developer(developer)
      get api("/projects/#{project.id}/terraform/state/#{state_name}"), headers: auth_header_for(developer)

      expect(response).to have_gitlab_http_status(:forbidden)
    end
  end
end
