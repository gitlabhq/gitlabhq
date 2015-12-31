require 'spec_helper'

describe API::API, api: true do
  include ApiHelpers

  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let!(:project) { create(:project, creator_id: user.id) }
  let!(:master) { create(:project_member, user: user, project: project, access_level: ProjectMember::MASTER) }
  let!(:developer) { create(:project_member, user: user2, project: project, access_level: ProjectMember::DEVELOPER) }
  let!(:variable) { create(:ci_variable, project: project) }

  describe 'GET /projects/:id/variables' do
    context 'authorized user with proper permissions' do
      it 'should return project variables' do
        get api("/projects/#{project.id}/variables", user)

        expect(response.status).to eq(200)
        expect(json_response).to be_a(Array)
      end
    end

    context 'authorized user with invalid permissions' do
      it 'should not return project variables' do
        get api("/projects/#{project.id}/variables", user2)

        expect(response.status).to eq(403)
      end
    end

    context 'unauthorized user' do
      it 'should not return project variables' do
        get api("/projects/#{project.id}/variables")

        expect(response.status).to eq(401)
      end
    end
  end

  describe 'GET /projects/:id/variables/:variable_id' do
    context 'authorized user with proper permissions' do
      it 'should return project variable details when ID is used as :variable_id' do
        get api("/projects/#{project.id}/variables/1", user)

        expect(response.status).to eq(200)
        expect(json_response['key']).to eq('TEST_VARIABLE_1')
        expect(json_response['value']).to eq('VALUE_1')
      end

      it 'should return project variable details when `key` is used as :variable_id' do
        get api("/projects/#{project.id}/variables/TEST_VARIABLE_1", user)

        expect(response.status).to eq(200)
        expect(json_response['id']).to eq(1)
        expect(json_response['value']).to eq('VALUE_1')
      end
    end

    context 'authorized user with invalid permissions' do
      it 'should not return project variable details' do
        get api("/projects/#{project.id}/variables/1", user2)

        expect(response.status).to eq(403)
      end
    end

    context 'unauthorized user' do
      it 'should not return project variable details' do
        get api("/projects/#{project.id}/variables/1")

        expect(response.status).to eq(401)
      end
    end
  end
end
