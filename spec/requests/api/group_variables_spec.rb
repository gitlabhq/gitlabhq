require 'spec_helper'

describe API::GroupVariables do
  let(:group) { create(:group) }
  let(:user) { create(:user) }

  describe 'GET /groups/:id/variables' do
    let!(:variable) { create(:ci_group_variable, group: group) }

    context 'authorized user with proper permissions' do
      before do
        group.add_master(user)
      end

      it 'returns group variables' do
        get api("/groups/#{group.id}/variables", user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_a(Array)
      end
    end

    context 'authorized user with invalid permissions' do
      it 'does not return group variables' do
        get api("/groups/#{group.id}/variables", user)

        expect(response).to have_gitlab_http_status(403)
      end
    end

    context 'unauthorized user' do
      it 'does not return group variables' do
        get api("/groups/#{group.id}/variables")

        expect(response).to have_gitlab_http_status(401)
      end
    end
  end

  describe 'GET /groups/:id/variables/:key' do
    let!(:variable) { create(:ci_group_variable, group: group) }

    context 'authorized user with proper permissions' do
      before do
        group.add_master(user)
      end

      it 'returns group variable details' do
        get api("/groups/#{group.id}/variables/#{variable.key}", user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['value']).to eq(variable.value)
        expect(json_response['protected']).to eq(variable.protected?)
      end

      it 'responds with 404 Not Found if requesting non-existing variable' do
        get api("/groups/#{group.id}/variables/non_existing_variable", user)

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'authorized user with invalid permissions' do
      it 'does not return group variable details' do
        get api("/groups/#{group.id}/variables/#{variable.key}", user)

        expect(response).to have_gitlab_http_status(403)
      end
    end

    context 'unauthorized user' do
      it 'does not return group variable details' do
        get api("/groups/#{group.id}/variables/#{variable.key}")

        expect(response).to have_gitlab_http_status(401)
      end
    end
  end

  describe 'POST /groups/:id/variables' do
    context 'authorized user with proper permissions' do
      let!(:variable) { create(:ci_group_variable, group: group) }

      before do
        group.add_master(user)
      end

      it 'creates variable' do
        expect do
          post api("/groups/#{group.id}/variables", user), key: 'TEST_VARIABLE_2', value: 'VALUE_2', protected: true
        end.to change {group.variables.count}.by(1)

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['key']).to eq('TEST_VARIABLE_2')
        expect(json_response['value']).to eq('VALUE_2')
        expect(json_response['protected']).to be_truthy
      end

      it 'creates variable with optional attributes' do
        expect do
          post api("/groups/#{group.id}/variables", user), key: 'TEST_VARIABLE_2', value: 'VALUE_2'
        end.to change {group.variables.count}.by(1)

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['key']).to eq('TEST_VARIABLE_2')
        expect(json_response['value']).to eq('VALUE_2')
        expect(json_response['protected']).to be_falsey
      end

      it 'does not allow to duplicate variable key' do
        expect do
          post api("/groups/#{group.id}/variables", user), key: variable.key, value: 'VALUE_2'
        end.to change {group.variables.count}.by(0)

        expect(response).to have_gitlab_http_status(400)
      end
    end

    context 'authorized user with invalid permissions' do
      it 'does not create variable' do
        post api("/groups/#{group.id}/variables", user)

        expect(response).to have_gitlab_http_status(403)
      end
    end

    context 'unauthorized user' do
      it 'does not create variable' do
        post api("/groups/#{group.id}/variables")

        expect(response).to have_gitlab_http_status(401)
      end
    end
  end

  describe 'PUT /groups/:id/variables/:key' do
    let!(:variable) { create(:ci_group_variable, group: group) }

    context 'authorized user with proper permissions' do
      before do
        group.add_master(user)
      end

      it 'updates variable data' do
        initial_variable = group.variables.reload.first
        value_before = initial_variable.value

        put api("/groups/#{group.id}/variables/#{variable.key}", user), value: 'VALUE_1_UP', protected: true

        updated_variable = group.variables.reload.first

        expect(response).to have_gitlab_http_status(200)
        expect(value_before).to eq(variable.value)
        expect(updated_variable.value).to eq('VALUE_1_UP')
        expect(updated_variable).to be_protected
      end

      it 'responds with 404 Not Found if requesting non-existing variable' do
        put api("/groups/#{group.id}/variables/non_existing_variable", user)

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'authorized user with invalid permissions' do
      it 'does not update variable' do
        put api("/groups/#{group.id}/variables/#{variable.key}", user)

        expect(response).to have_gitlab_http_status(403)
      end
    end

    context 'unauthorized user' do
      it 'does not update variable' do
        put api("/groups/#{group.id}/variables/#{variable.key}")

        expect(response).to have_gitlab_http_status(401)
      end
    end
  end

  describe 'DELETE /groups/:id/variables/:key' do
    let!(:variable) { create(:ci_group_variable, group: group) }

    context 'authorized user with proper permissions' do
      before do
        group.add_master(user)
      end

      it 'deletes variable' do
        expect do
          delete api("/groups/#{group.id}/variables/#{variable.key}", user)

          expect(response).to have_gitlab_http_status(204)
        end.to change {group.variables.count}.by(-1)
      end

      it 'responds with 404 Not Found if requesting non-existing variable' do
        delete api("/groups/#{group.id}/variables/non_existing_variable", user)

        expect(response).to have_gitlab_http_status(404)
      end

      it_behaves_like '412 response' do
        let(:request) { api("/groups/#{group.id}/variables/#{variable.key}", user) }
      end
    end

    context 'authorized user with invalid permissions' do
      it 'does not delete variable' do
        delete api("/groups/#{group.id}/variables/#{variable.key}", user)

        expect(response).to have_gitlab_http_status(403)
      end
    end

    context 'unauthorized user' do
      it 'does not delete variable' do
        delete api("/groups/#{group.id}/variables/#{variable.key}")

        expect(response).to have_gitlab_http_status(401)
      end
    end
  end
end
