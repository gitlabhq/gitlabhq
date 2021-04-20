# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::GroupVariables do
  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:variable) { create(:ci_group_variable, group: group) }

  let(:access_level) {}

  before do
    group.add_user(user, access_level) if access_level
  end

  describe 'GET /groups/:id/variables' do
    context 'authorized user with proper permissions' do
      let(:access_level) { :owner }

      it 'returns group variables' do
        get api("/groups/#{group.id}/variables", user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_a(Array)
      end
    end

    context 'authorized user with invalid permissions' do
      let(:access_level) { :maintainer }

      it 'does not return group variables' do
        get api("/groups/#{group.id}/variables", user)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'unauthorized user' do
      it 'does not return group variables' do
        get api("/groups/#{group.id}/variables")

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  describe 'GET /groups/:id/variables/:key' do
    context 'authorized user with proper permissions' do
      let(:access_level) { :owner }

      it 'returns group variable details' do
        get api("/groups/#{group.id}/variables/#{variable.key}", user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['value']).to eq(variable.value)
        expect(json_response['protected']).to eq(variable.protected?)
        expect(json_response['variable_type']).to eq(variable.variable_type)
        expect(json_response['environment_scope']).to eq(variable.environment_scope)
      end

      it 'responds with 404 Not Found if requesting non-existing variable' do
        get api("/groups/#{group.id}/variables/non_existing_variable", user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'authorized user with invalid permissions' do
      let(:access_level) { :maintainer }

      it 'does not return group variable details' do
        get api("/groups/#{group.id}/variables/#{variable.key}", user)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'unauthorized user' do
      it 'does not return group variable details' do
        get api("/groups/#{group.id}/variables/#{variable.key}")

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  describe 'POST /groups/:id/variables' do
    context 'authorized user with proper permissions' do
      let(:access_level) { :owner }

      it 'creates variable' do
        expect do
          post api("/groups/#{group.id}/variables", user), params: { key: 'TEST_VARIABLE_2', value: 'PROTECTED_VALUE_2', protected: true, masked: true }
        end.to change {group.variables.count}.by(1)

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['key']).to eq('TEST_VARIABLE_2')
        expect(json_response['value']).to eq('PROTECTED_VALUE_2')
        expect(json_response['protected']).to be_truthy
        expect(json_response['masked']).to be_truthy
        expect(json_response['variable_type']).to eq('env_var')
        expect(json_response['environment_scope']).to eq('*')
      end

      it 'creates variable with optional attributes' do
        expect do
          post api("/groups/#{group.id}/variables", user), params: { variable_type: 'file', key: 'TEST_VARIABLE_2', value: 'VALUE_2' }
        end.to change {group.variables.count}.by(1)

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['key']).to eq('TEST_VARIABLE_2')
        expect(json_response['value']).to eq('VALUE_2')
        expect(json_response['protected']).to be_falsey
        expect(json_response['masked']).to be_falsey
        expect(json_response['variable_type']).to eq('file')
        expect(json_response['environment_scope']).to eq('*')
      end

      it 'does not allow to duplicate variable key' do
        expect do
          post api("/groups/#{group.id}/variables", user), params: { key: variable.key, value: 'VALUE_2' }
        end.to change {group.variables.count}.by(0)

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'authorized user with invalid permissions' do
      let(:access_level) { :maintainer }

      it 'does not create variable' do
        post api("/groups/#{group.id}/variables", user)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'unauthorized user' do
      it 'does not create variable' do
        post api("/groups/#{group.id}/variables")

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  describe 'PUT /groups/:id/variables/:key' do
    context 'authorized user with proper permissions' do
      let(:access_level) { :owner }

      it 'updates variable data' do
        initial_variable = group.variables.reload.first
        value_before = initial_variable.value

        put api("/groups/#{group.id}/variables/#{variable.key}", user), params: { variable_type: 'file', value: 'VALUE_1_UP', protected: true, masked: true }

        updated_variable = group.variables.reload.first

        expect(response).to have_gitlab_http_status(:ok)
        expect(value_before).to eq(variable.value)
        expect(updated_variable.value).to eq('VALUE_1_UP')
        expect(updated_variable).to be_protected
        expect(json_response['variable_type']).to eq('file')
        expect(json_response['masked']).to be_truthy
      end

      it 'responds with 404 Not Found if requesting non-existing variable' do
        put api("/groups/#{group.id}/variables/non_existing_variable", user)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'responds with 400 if the update fails' do
        put api("/groups/#{group.id}/variables/#{variable.key}", user), params: { value: 'shrt', masked: true }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(variable.reload.masked).to eq(false)
        expect(json_response['message']).to eq('value' => ['is invalid'])
      end
    end

    context 'authorized user with invalid permissions' do
      let(:access_level) { :maintainer }

      it 'does not update variable' do
        put api("/groups/#{group.id}/variables/#{variable.key}", user)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'unauthorized user' do
      it 'does not update variable' do
        put api("/groups/#{group.id}/variables/#{variable.key}")

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  describe 'DELETE /groups/:id/variables/:key' do
    context 'authorized user with proper permissions' do
      let(:access_level) { :owner }

      it 'deletes variable' do
        expect do
          delete api("/groups/#{group.id}/variables/#{variable.key}", user)

          expect(response).to have_gitlab_http_status(:no_content)
        end.to change {group.variables.count}.by(-1)
      end

      it 'responds with 404 Not Found if requesting non-existing variable' do
        delete api("/groups/#{group.id}/variables/non_existing_variable", user)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it_behaves_like '412 response' do
        let(:request) { api("/groups/#{group.id}/variables/#{variable.key}", user) }
      end
    end

    context 'authorized user with invalid permissions' do
      let(:access_level) { :maintainer }

      it 'does not delete variable' do
        delete api("/groups/#{group.id}/variables/#{variable.key}", user)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'unauthorized user' do
      it 'does not delete variable' do
        delete api("/groups/#{group.id}/variables/#{variable.key}")

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end
end
