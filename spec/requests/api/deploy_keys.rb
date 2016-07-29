require 'spec_helper'

describe API::API, api: true  do
  include ApiHelpers

  let(:user)  { create(:user) }
  let(:project) { create(:project, creator_id: user.id) }
  let!(:deploy_keys_project) { create(:deploy_keys_project, project: project) }
  let(:admin) { create(:admin) }

  describe 'GET /deploy_keys' do
    before { admin }

    context 'when unauthenticated' do
      it 'should return authentication error' do
        get api('/deploy_keys')
        expect(response.status).to eq(401)
      end
    end

    context 'when authenticated as non-admin user' do
      it 'should return a 403 error' do
        get api('/deploy_keys', user)
        expect(response.status).to eq(403)
      end
    end

    context 'when authenticated as admin' do
      it 'should return all deploy keys' do
        get api('/deploy_keys', admin)
        expect(response.status).to eq(200)

        expect(json_response).to be_an Array
        expect(json_response.first['id']).to eq(deploy_keys_project.deploy_key.id)
      end
    end
  end
end
