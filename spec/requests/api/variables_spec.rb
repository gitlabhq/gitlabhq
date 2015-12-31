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
        get api("/projects/#{project.id}/variables/#{variable.id}", user)

        expect(response.status).to eq(200)
        expect(json_response['key']).to eq(variable.key)
        expect(json_response['value']).to eq(variable.value)
      end

      it 'should return project variable details when `key` is used as :variable_id' do
        get api("/projects/#{project.id}/variables/#{variable.key}", user)

        expect(response.status).to eq(200)
        expect(json_response['id']).to eq(variable.id)
        expect(json_response['value']).to eq(variable.value)
      end
    end

    context 'authorized user with invalid permissions' do
      it 'should not return project variable details' do
        get api("/projects/#{project.id}/variables/#{variable.id}", user2)

        expect(response.status).to eq(403)
      end
    end

    context 'unauthorized user' do
      it 'should not return project variable details' do
        get api("/projects/#{project.id}/variables/#{variable.id}")

        expect(response.status).to eq(401)
      end
    end
  end

  describe 'PUT /projects/:id/variables/:variable_id' do
    context 'authorized user with proper permissions' do
      it 'should update variable data' do
        initial_variable = project.variables.first
        key_before = initial_variable.key
        value_before = initial_variable.value

        put api("/projects/#{project.id}/variables/#{variable.id}", user), key: 'TEST_VARIABLE_1_UP', value: 'VALUE_1_UP'

        updated_variable = project.variables.first

        expect(response.status).to eq(200)
        expect(key_before).to eq(variable.key)
        expect(value_before).to eq(variable.value)
        expect(updated_variable.key).to eq('TEST_VARIABLE_1_UP')
        expect(updated_variable.value).to eq('VALUE_1_UP')
      end
    end

    context 'authorized user with invalid permissions' do
      it 'should not update variable' do
        put api("/projects/#{project.id}/variables/#{variable.id}", user2)

        expect(response.status).to eq(403)
      end
    end

    context 'unauthorized user' do
      it 'should not return project variable details' do
        put api("/projects/#{project.id}/variables/#{variable.id}")

        expect(response.status).to eq(401)
      end
    end
  end
end
