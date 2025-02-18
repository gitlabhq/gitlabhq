# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::API::Admin::Ci::Variables, :aggregate_failures, feature_category: :ci_variables do
  let_it_be(:admin) { create(:admin) }
  let_it_be(:user) { create(:user) }
  let_it_be(:variable) { create(:ci_instance_variable) }
  let_it_be(:path) { '/admin/ci/variables' }

  describe 'GET /admin/ci/variables' do
    it_behaves_like 'GET request permissions for admin mode'

    it 'returns instance-level variables for admins' do
      get api(path, admin, admin_mode: true)

      expect(json_response).to be_a(Array)
    end

    it 'does not return instance-level variables for unauthorized users' do
      get api(path, admin_mode: true)

      expect(response).to have_gitlab_http_status(:unauthorized)
    end
  end

  describe 'GET /admin/ci/variables/:key' do
    let_it_be(:path) { "/admin/ci/variables/#{variable.key}" }

    it_behaves_like 'GET request permissions for admin mode'

    it 'returns instance-level variable details for admins' do
      get api(path, admin, admin_mode: true)

      expect(json_response['value']).to eq(variable.value)
      expect(json_response['protected']).to eq(variable.protected?)
      expect(json_response['variable_type']).to eq(variable.variable_type)
    end

    it 'responds with 404 Not Found if requesting non-existing variable' do
      get api('/admin/ci/variables/non_existing_variable', admin, admin_mode: true)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'does not return instance-level variable details for unauthorized users' do
      get api(path, admin_mode: true)

      expect(response).to have_gitlab_http_status(:unauthorized)
    end
  end

  describe 'POST /admin/ci/variables' do
    it_behaves_like 'POST request permissions for admin mode' do
      let(:params) { { key: 'KEY', value: 'VALUE' } }
    end

    context 'authorized user with proper permissions' do
      it 'creates variable for admins' do
        expect do
          post api(path, admin, admin_mode: true),
            params: {
              key: 'TEST_VARIABLE_2',
              value: 'PROTECTED_VALUE_2',
              protected: true,
              masked: true,
              raw: true
            }
        end.to change { ::Ci::InstanceVariable.count }.by(1)

        expect(json_response['key']).to eq('TEST_VARIABLE_2')
        expect(json_response['value']).to eq('PROTECTED_VALUE_2')
        expect(json_response['protected']).to be_truthy
        expect(json_response['masked']).to be_truthy
        expect(json_response['raw']).to be_truthy
        expect(json_response['variable_type']).to eq('env_var')
      end

      it 'masks the new value when logging' do
        masked_params = { 'key' => 'VAR_KEY', 'value' => '[FILTERED]', 'protected' => 'true', 'masked' => 'true' }

        expect(::API::API::LOGGER).to receive(:info).with(include(params: include(masked_params)))

        post api(path, user, admin_mode: true),
          params: { key: 'VAR_KEY', value: 'SENSITIVE', protected: true, masked: true }
      end

      it 'creates variable with optional attributes' do
        expect do
          post api(path, admin, admin_mode: true),
            params: {
              variable_type: 'file',
              key: 'TEST_VARIABLE_2',
              value: 'VALUE_2'
            }
        end.to change { ::Ci::InstanceVariable.count }.by(1)

        expect(json_response['key']).to eq('TEST_VARIABLE_2')
        expect(json_response['value']).to eq('VALUE_2')
        expect(json_response['protected']).to be_falsey
        expect(json_response['masked']).to be_falsey
        expect(json_response['raw']).to be_falsey
        expect(json_response['variable_type']).to eq('file')
      end

      it 'does not allow to duplicate variable key' do
        expect do
          post api(path, admin, admin_mode: true),
            params: { key: variable.key, value: 'VALUE_2' }
        end.not_to change { ::Ci::InstanceVariable.count }

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'does not allow values above 10,000 characters' do
        too_long_message = <<~MESSAGE.strip
          The value of the provided variable exceeds the 10000 character limit
        MESSAGE

        expect do
          post api(path, admin, admin_mode: true),
            params: { key: 'too_long', value: SecureRandom.hex(10_001) }
        end.not_to change { ::Ci::InstanceVariable.count }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response).to match('message' =>
          a_hash_including('value' => [too_long_message]))
      end
    end

    context 'unauthorized user' do
      it 'does not create variable' do
        post api(path, admin_mode: true)

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  describe 'PUT /admin/ci/variables/:key' do
    let_it_be(:path) { "/admin/ci/variables/#{variable.key}" }
    let_it_be(:params) do
      {
        variable_type: 'file',
        value: 'VALUE_1_UP',
        protected: true,
        masked: true,
        raw: true
      }
    end

    it_behaves_like 'PUT request permissions for admin mode'

    context 'authorized user with proper permissions' do
      it 'updates variable data' do
        put api(path, admin, admin_mode: true), params: params

        expect(variable.reload.value).to eq('VALUE_1_UP')
        expect(variable.reload).to be_protected
        expect(json_response['variable_type']).to eq('file')
        expect(json_response['masked']).to be_truthy
        expect(json_response['raw']).to be_truthy
      end

      it 'masks the new value when logging' do
        masked_params = { 'value' => '[FILTERED]', 'protected' => 'true', 'masked' => 'true' }

        expect(::API::API::LOGGER).to receive(:info).with(include(params: include(masked_params)))

        put api(path, admin, admin_mode: true),
          params: { value: 'SENSITIVE', protected: true, masked: true }
      end

      it 'responds with 404 Not Found if requesting non-existing variable' do
        put api('/admin/ci/variables/non_existing_variable', admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'unauthorized user' do
      it 'does not update variable' do
        put api(path, admin_mode: true)

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  describe 'DELETE /admin/ci/variables/:key' do
    let_it_be(:path) { "/admin/ci/variables/#{variable.key}" }

    it_behaves_like 'DELETE request permissions for admin mode'

    context 'authorized user with proper permissions' do
      it 'deletes variable' do
        expect do
          delete api(path, admin, admin_mode: true)
        end.to change { ::Ci::InstanceVariable.count }.by(-1)
      end

      it 'responds with 404 Not Found if requesting non-existing variable' do
        delete api('/admin/ci/variables/non_existing_variable', admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'unauthorized user' do
      it 'does not delete variable' do
        delete api(path, admin_mode: true)

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end
end
