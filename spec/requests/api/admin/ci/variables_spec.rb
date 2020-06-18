# frozen_string_literal: true

require 'spec_helper'

describe ::API::Admin::Ci::Variables do
  let_it_be(:admin) { create(:admin) }
  let_it_be(:user) { create(:user) }

  describe 'GET /admin/ci/variables' do
    let!(:variable) { create(:ci_instance_variable) }

    it 'returns instance-level variables for admins', :aggregate_failures do
      get api('/admin/ci/variables', admin)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to be_a(Array)
    end

    it 'does not return instance-level variables for regular users' do
      get api('/admin/ci/variables', user)

      expect(response).to have_gitlab_http_status(:forbidden)
    end

    it 'does not return instance-level variables for unauthorized users' do
      get api('/admin/ci/variables')

      expect(response).to have_gitlab_http_status(:unauthorized)
    end
  end

  describe 'GET /admin/ci/variables/:key' do
    let!(:variable) { create(:ci_instance_variable) }

    it 'returns instance-level variable details for admins', :aggregate_failures do
      get api("/admin/ci/variables/#{variable.key}", admin)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['value']).to eq(variable.value)
      expect(json_response['protected']).to eq(variable.protected?)
      expect(json_response['variable_type']).to eq(variable.variable_type)
    end

    it 'responds with 404 Not Found if requesting non-existing variable' do
      get api('/admin/ci/variables/non_existing_variable', admin)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'does not return instance-level variable details for regular users' do
      get api("/admin/ci/variables/#{variable.key}", user)

      expect(response).to have_gitlab_http_status(:forbidden)
    end

    it 'does not return instance-level variable details for unauthorized users' do
      get api("/admin/ci/variables/#{variable.key}")

      expect(response).to have_gitlab_http_status(:unauthorized)
    end
  end

  describe 'POST /admin/ci/variables' do
    context 'authorized user with proper permissions' do
      let!(:variable) { create(:ci_instance_variable) }

      it 'creates variable for admins', :aggregate_failures do
        expect do
          post api('/admin/ci/variables', admin),
            params: {
              key: 'TEST_VARIABLE_2',
              value: 'PROTECTED_VALUE_2',
              protected: true,
              masked: true
            }
        end.to change { ::Ci::InstanceVariable.count }.by(1)

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['key']).to eq('TEST_VARIABLE_2')
        expect(json_response['value']).to eq('PROTECTED_VALUE_2')
        expect(json_response['protected']).to be_truthy
        expect(json_response['masked']).to be_truthy
        expect(json_response['variable_type']).to eq('env_var')
      end

      it 'creates variable with optional attributes', :aggregate_failures do
        expect do
          post api('/admin/ci/variables', admin),
            params: {
              variable_type: 'file',
              key: 'TEST_VARIABLE_2',
              value: 'VALUE_2'
            }
        end.to change { ::Ci::InstanceVariable.count }.by(1)

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['key']).to eq('TEST_VARIABLE_2')
        expect(json_response['value']).to eq('VALUE_2')
        expect(json_response['protected']).to be_falsey
        expect(json_response['masked']).to be_falsey
        expect(json_response['variable_type']).to eq('file')
      end

      it 'does not allow to duplicate variable key' do
        expect do
          post api('/admin/ci/variables', admin),
            params: { key: variable.key, value: 'VALUE_2' }
        end.not_to change { ::Ci::InstanceVariable.count }

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'does not allow values above 700 characters' do
        too_long_message = <<~MESSAGE.strip
          The encrypted value of the provided variable exceeds 1024 bytes. \
          Variables over 700 characters risk exceeding the limit.
        MESSAGE

        expect do
          post api('/admin/ci/variables', admin),
            params: { key: 'too_long', value: SecureRandom.hex(701) }
        end.not_to change { ::Ci::InstanceVariable.count }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response).to match('message' =>
          a_hash_including('encrypted_value' => [too_long_message]))
      end
    end

    context 'authorized user with invalid permissions' do
      it 'does not create variable' do
        post api('/admin/ci/variables', user)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'unauthorized user' do
      it 'does not create variable' do
        post api('/admin/ci/variables')

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  describe 'PUT /admin/ci/variables/:key' do
    let!(:variable) { create(:ci_instance_variable) }

    context 'authorized user with proper permissions' do
      it 'updates variable data', :aggregate_failures do
        put api("/admin/ci/variables/#{variable.key}", admin),
          params: {
            variable_type: 'file',
            value: 'VALUE_1_UP',
            protected: true,
            masked: true
          }

        expect(response).to have_gitlab_http_status(:ok)
        expect(variable.reload.value).to eq('VALUE_1_UP')
        expect(variable.reload).to be_protected
        expect(json_response['variable_type']).to eq('file')
        expect(json_response['masked']).to be_truthy
      end

      it 'responds with 404 Not Found if requesting non-existing variable' do
        put api('/admin/ci/variables/non_existing_variable', admin)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'authorized user with invalid permissions' do
      it 'does not update variable' do
        put api("/admin/ci/variables/#{variable.key}", user)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'unauthorized user' do
      it 'does not update variable' do
        put api("/admin/ci/variables/#{variable.key}")

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  describe 'DELETE /admin/ci/variables/:key' do
    let!(:variable) { create(:ci_instance_variable) }

    context 'authorized user with proper permissions' do
      it 'deletes variable' do
        expect do
          delete api("/admin/ci/variables/#{variable.key}", admin)

          expect(response).to have_gitlab_http_status(:no_content)
        end.to change { ::Ci::InstanceVariable.count }.by(-1)
      end

      it 'responds with 404 Not Found if requesting non-existing variable' do
        delete api('/admin/ci/variables/non_existing_variable', admin)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'authorized user with invalid permissions' do
      it 'does not delete variable' do
        delete api("/admin/ci/variables/#{variable.key}", user)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'unauthorized user' do
      it 'does not delete variable' do
        delete api("/admin/ci/variables/#{variable.key}")

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end
end
