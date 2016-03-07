require 'spec_helper'

describe API::API, api: true do
  include ApiHelpers

  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let!(:project) { create(:project, creator_id: user.id) }
  let!(:master) { create(:project_member, :master, user: user, project: project) }
  let!(:developer) { create(:project_member, :developer, user: user2, project: project) }
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

  describe 'GET /projects/:id/variables/:key' do
    context 'authorized user with proper permissions' do
      it 'should return project variable details' do
        get api("/projects/#{project.id}/variables/#{variable.key}", user)

        expect(response.status).to eq(200)
        expect(json_response['value']).to eq(variable.value)
      end

      it 'should respond with 404 Not Found if requesting non-existing variable' do
        get api("/projects/#{project.id}/variables/non_existing_variable", user)

        expect(response.status).to eq(404)
      end
    end

    context 'authorized user with invalid permissions' do
      it 'should not return project variable details' do
        get api("/projects/#{project.id}/variables/#{variable.key}", user2)

        expect(response.status).to eq(403)
      end
    end

    context 'unauthorized user' do
      it 'should not return project variable details' do
        get api("/projects/#{project.id}/variables/#{variable.key}")

        expect(response.status).to eq(401)
      end
    end
  end

  describe 'POST /projects/:id/variables' do
    context 'authorized user with proper permissions' do
      it 'should create variable' do
        expect do
          post api("/projects/#{project.id}/variables", user), key: 'TEST_VARIABLE_2', value: 'VALUE_2'
        end.to change{project.variables.count}.by(1)

        expect(response.status).to eq(201)
        expect(json_response['key']).to eq('TEST_VARIABLE_2')
        expect(json_response['value']).to eq('VALUE_2')
      end

      it 'should not allow to duplicate variable key' do
        expect do
          post api("/projects/#{project.id}/variables", user), key: variable.key, value: 'VALUE_2'
        end.to change{project.variables.count}.by(0)

        expect(response.status).to eq(400)
      end
    end

    context 'authorized user with invalid permissions' do
      it 'should not create variable' do
        post api("/projects/#{project.id}/variables", user2)

        expect(response.status).to eq(403)
      end
    end

    context 'unauthorized user' do
      it 'should not create variable' do
        post api("/projects/#{project.id}/variables")

        expect(response.status).to eq(401)
      end
    end
  end

  describe 'PUT /projects/:id/variables/:key' do
    context 'authorized user with proper permissions' do
      it 'should update variable data' do
        initial_variable = project.variables.first
        value_before = initial_variable.value

        put api("/projects/#{project.id}/variables/#{variable.key}", user), value: 'VALUE_1_UP'

        updated_variable = project.variables.first

        expect(response.status).to eq(200)
        expect(value_before).to eq(variable.value)
        expect(updated_variable.value).to eq('VALUE_1_UP')
      end

      it 'should responde with 404 Not Found if requesting non-existing variable' do
        put api("/projects/#{project.id}/variables/non_existing_variable", user)

        expect(response.status).to eq(404)
      end
    end

    context 'authorized user with invalid permissions' do
      it 'should not update variable' do
        put api("/projects/#{project.id}/variables/#{variable.key}", user2)

        expect(response.status).to eq(403)
      end
    end

    context 'unauthorized user' do
      it 'should not update variable' do
        put api("/projects/#{project.id}/variables/#{variable.key}")

        expect(response.status).to eq(401)
      end
    end
  end

  describe 'DELETE /projects/:id/variables/:key' do
    context 'authorized user with proper permissions' do
      it 'should delete variable' do
        expect do
          delete api("/projects/#{project.id}/variables/#{variable.key}", user)
        end.to change{project.variables.count}.by(-1)
        expect(response.status).to eq(200)
      end

      it 'should responde with 404 Not Found if requesting non-existing variable' do
        delete api("/projects/#{project.id}/variables/non_existing_variable", user)

        expect(response.status).to eq(404)
      end
    end

    context 'authorized user with invalid permissions' do
      it 'should not delete variable' do
        delete api("/projects/#{project.id}/variables/#{variable.key}", user2)

        expect(response.status).to eq(403)
      end
    end

    context 'unauthorized user' do
      it 'should not delete variable' do
        delete api("/projects/#{project.id}/variables/#{variable.key}")

        expect(response.status).to eq(401)
      end
    end
  end
end
