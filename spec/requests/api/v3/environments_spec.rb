require 'spec_helper'

describe API::V3::Environments, api: true  do
  include ApiHelpers

  let(:user)          { create(:user) }
  let(:non_member)    { create(:user) }
  let(:project)       { create(:empty_project, :private, namespace: user.namespace) }
  let!(:environment)  { create(:environment, project: project) }

  before do
    project.team << [user, :master]
  end

  describe 'DELETE /projects/:id/environments/:environment_id' do
    context 'as a master' do
      it 'returns a 200 for an existing environment' do
        delete v3_api("/projects/#{project.id}/environments/#{environment.id}", user)

        expect(response).to have_http_status(200)
      end

      it 'returns a 404 for non existing id' do
        delete v3_api("/projects/#{project.id}/environments/12345", user)

        expect(response).to have_http_status(404)
        expect(json_response['message']).to eq('404 Not found')
      end
    end

    context 'a non member' do
      it 'rejects the request' do
        delete v3_api("/projects/#{project.id}/environments/#{environment.id}", non_member)

        expect(response).to have_http_status(404)
      end
    end
  end
end
