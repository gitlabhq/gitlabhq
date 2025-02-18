# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Ci::Variables, feature_category: :ci_variables do
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let!(:project) { create(:project, creator_id: user.id) }
  let!(:maintainer) { create(:project_member, :maintainer, user: user, project: project) }
  let!(:developer) { create(:project_member, :developer, user: user2, project: project) }
  let(:is_hidden_variable) { true }
  let(:is_masked_variable) { true }
  let!(:variable) { create(:ci_variable, project: project, hidden: is_hidden_variable, masked: is_masked_variable) }

  describe 'GET /projects/:id/variables' do
    context 'authorized user with proper permissions' do
      it 'returns project variables' do
        get api("/projects/#{project.id}/variables", user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_a(Array)
      end
    end

    context 'authorized user with invalid permissions' do
      it 'does not return project variables' do
        get api("/projects/#{project.id}/variables", user2)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'unauthorized user' do
      it 'does not return project variables' do
        get api("/projects/#{project.id}/variables")

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  describe 'GET /projects/:id/variables/:key' do
    context 'authorized user with proper permissions' do
      context 'when variable is hidden' do
        let(:is_hidden_variable) { true }

        it 'returns project variable details and cut the value' do
          get api("/projects/#{project.id}/variables/#{variable.key}", user)

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['value']).to be_nil
          expect(json_response['protected']).to eq(variable.protected?)
          expect(json_response['masked']).to eq(variable.masked?)
          expect(json_response['raw']).to eq(variable.raw?)
          expect(json_response['variable_type']).to eq('env_var')
          expect(json_response['description']).to be_nil
          expect(json_response['hidden']).to eq(true)
        end
      end

      context 'when variable is not hidden' do
        let(:is_hidden_variable) { false }
        let(:is_masked_variable) { false }

        it 'returns project variable details' do
          get api("/projects/#{project.id}/variables/#{variable.key}", user)

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['value']).to eq(variable.value)
          expect(json_response['protected']).to eq(variable.protected?)
          expect(json_response['masked']).to eq(variable.masked?)
          expect(json_response['raw']).to eq(variable.raw?)
          expect(json_response['variable_type']).to eq('env_var')
          expect(json_response['description']).to be_nil
          expect(json_response['hidden']).to eq(false)
        end
      end

      it 'responds with 404 Not Found if requesting non-existing variable' do
        get api("/projects/#{project.id}/variables/non_existing_variable", user)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      context 'when there are two variables with the same key on different env' do
        let!(:var1) { create(:ci_variable, project: project, key: 'key1', environment_scope: 'staging') }
        let!(:var2) { create(:ci_variable, project: project, key: 'key1', environment_scope: 'production') }

        context 'when filter[environment_scope] is not passed' do
          it 'returns 409' do
            get api("/projects/#{project.id}/variables/key1", user)

            expect(response).to have_gitlab_http_status(:conflict)
          end
        end

        context 'when filter[environment_scope] is passed' do
          it 'returns the variable' do
            get api("/projects/#{project.id}/variables/key1", user), params: { 'filter[environment_scope]': 'production' }

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response['value']).to eq(var2.value)
          end
        end

        context 'when wrong filter[environment_scope] is passed' do
          it 'returns not_found' do
            get api("/projects/#{project.id}/variables/key1", user), params: { 'filter[environment_scope]': 'invalid' }

            expect(response).to have_gitlab_http_status(:not_found)
          end

          context 'when there is only one variable with provided key' do
            it 'returns not_found' do
              get api("/projects/#{project.id}/variables/#{variable.key}", user), params: { 'filter[environment_scope]': 'invalid' }

              expect(response).to have_gitlab_http_status(:not_found)
            end
          end
        end
      end
    end

    context 'authorized user with invalid permissions' do
      it 'does not return project variable details' do
        get api("/projects/#{project.id}/variables/#{variable.key}", user2)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'unauthorized user' do
      it 'does not return project variable details' do
        get api("/projects/#{project.id}/variables/#{variable.key}")

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  describe 'POST /projects/:id/variables' do
    context 'authorized user with proper permissions' do
      context 'when the project is below the plan limit for variables' do
        it 'creates variable' do
          expect do
            post api("/projects/#{project.id}/variables", user), params: { key: 'TEST_VARIABLE_2', value: 'PROTECTED_VALUE_2', protected: true, masked: true, raw: true }
          end.to change { project.variables.count }.by(1)

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response['key']).to eq('TEST_VARIABLE_2')
          expect(json_response['value']).to eq('PROTECTED_VALUE_2')
          expect(json_response['protected']).to be_truthy
          expect(json_response['hidden']).to eq(false)
          expect(json_response['masked']).to be_truthy
          expect(json_response['raw']).to be_truthy
          expect(json_response['variable_type']).to eq('env_var')
        end

        it 'creates variable with masked and hidden' do
          expect do
            post api("/projects/#{project.id}/variables", user), params: { key: 'TEST_VARIABLE_2', value: 'PROTECTED_VALUE_2', protected: true, masked_and_hidden: true, raw: true }
          end.to change { project.variables.count }.by(1)

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response['key']).to eq('TEST_VARIABLE_2')
          expect(json_response['value']).to be_nil
          expect(json_response['protected']).to be_truthy
          expect(json_response['hidden']).to eq(true)
          expect(json_response['masked']).to be_truthy
          expect(json_response['raw']).to be_truthy
          expect(json_response['variable_type']).to eq('env_var')
        end

        it 'masks the new value when logging' do
          masked_params = { 'key' => 'VAR_KEY', 'value' => '[FILTERED]', 'protected' => 'true', 'masked' => 'true' }

          expect(::API::API::LOGGER).to receive(:info).with(include(params: include(masked_params)))

          post api("/projects/#{project.id}/variables", user),
            params: { key: 'VAR_KEY', value: 'SENSITIVE', protected: true, masked: true }
        end

        it 'creates variable with optional attributes' do
          expect do
            post api("/projects/#{project.id}/variables", user), params: { variable_type: 'file', key: 'TEST_VARIABLE_2', value: 'VALUE_2', description: 'description' }
          end.to change { project.variables.count }.by(1)

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response['key']).to eq('TEST_VARIABLE_2')
          expect(json_response['value']).to eq('VALUE_2')
          expect(json_response['protected']).to be_falsey
          expect(json_response['masked']).to be_falsey
          expect(json_response['raw']).to be_falsey
          expect(json_response['variable_type']).to eq('file')
          expect(json_response['description']).to eq('description')
          expect(json_response['hidden']).to eq(false)
        end

        it 'does not allow to duplicate variable key' do
          expect do
            post api("/projects/#{project.id}/variables", user), params: { key: variable.key, value: 'VALUE_2' }
          end.to change { project.variables.count }.by(0)

          expect(response).to have_gitlab_http_status(:bad_request)
        end

        it 'creates variable with a specific environment scope' do
          expect do
            post api("/projects/#{project.id}/variables", user), params: { key: 'TEST_VARIABLE_2', value: 'VALUE_2', environment_scope: 'review/*' }
          end.to change { project.variables.reload.count }.by(1)

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response['key']).to eq('TEST_VARIABLE_2')
          expect(json_response['value']).to eq('VALUE_2')
          expect(json_response['environment_scope']).to eq('review/*')
        end

        it 'allows duplicated variable key given different environment scopes' do
          variable = create(:ci_variable, project: project)

          expect do
            post api("/projects/#{project.id}/variables", user), params: { key: variable.key, value: 'VALUE_2', environment_scope: 'review/*' }
          end.to change { project.variables.reload.count }.by(1)

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response['key']).to eq(variable.key)
          expect(json_response['value']).to eq('VALUE_2')
          expect(json_response['environment_scope']).to eq('review/*')
        end
      end

      context 'when the project is at the plan limit for variables' do
        before do
          create(:plan_limits, :default_plan, project_ci_variables: 1)
        end

        it 'returns a variable limit error' do
          expect do
            post api("/projects/#{project.id}/variables", user), params: { key: 'TOO_MANY_VARS', value: 'too many' }
          end.not_to change { project.variables.count }

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']['base']).to contain_exactly(
            'Maximum number of project ci variables (1) exceeded'
          )
        end
      end
    end

    context 'authorized user with invalid permissions' do
      it 'does not create variable' do
        post api("/projects/#{project.id}/variables", user2)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'unauthorized user' do
      it 'does not create variable' do
        post api("/projects/#{project.id}/variables")

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  describe 'PUT /projects/:id/variables/:key' do
    context 'authorized user with proper permissions' do
      it 'updates variable data' do
        initial_variable = project.variables.reload.first
        value_before = initial_variable.value

        put api("/projects/#{project.id}/variables/#{variable.key}", user), params: { variable_type: 'file', value: 'VALUE_1_UP', protected: true, description: 'updated' }

        updated_variable = project.variables.reload.first

        expect(response).to have_gitlab_http_status(:ok)
        expect(value_before).to eq(variable.value)
        expect(updated_variable.value).to eq('VALUE_1_UP')
        expect(updated_variable).to be_protected
        expect(updated_variable.variable_type).to eq('file')
        expect(updated_variable.description).to eq('updated')
      end

      context 'when variable is hidden' do
        it 'unable to update masked attribute' do
          put api("/projects/#{project.id}/variables/#{variable.key}", user), params: { masked: false }

          updated_variable = project.variables.reload.first

          expect(response).to have_gitlab_http_status(:bad_request)

          expected_error_message = 'The visibility setting cannot be changed for masked and hidden variables.'

          expect(json_response['message']['base']).to contain_exactly(expected_error_message)
          expect(updated_variable).to be_masked
        end
      end

      context 'when variable is not hidden' do
        let(:is_hidden_variable) { false }
        let(:is_masked_variable) { false }

        it 'updates masked attribute' do
          put api("/projects/#{project.id}/variables/#{variable.key}", user), params: { masked: true }

          updated_variable = project.variables.reload.first

          expect(response).to have_gitlab_http_status(:ok)
          expect(updated_variable).to be_masked
        end
      end

      it 'masks the new value when logging' do
        masked_params = { 'value' => '[FILTERED]', 'protected' => 'true' }

        expect(::API::API::LOGGER).to receive(:info).with(include(params: include(masked_params)))

        put api("/projects/#{project.id}/variables/#{variable.key}", user),
          params: { value: 'SENSITIVE', protected: true }
      end

      it 'responds with 404 Not Found if requesting non-existing variable' do
        put api("/projects/#{project.id}/variables/non_existing_variable", user)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      context 'when there are two variables with the same key on different env' do
        let!(:var1) { create(:ci_variable, project: project, key: 'key1', environment_scope: 'staging') }
        let!(:var2) { create(:ci_variable, project: project, key: 'key1', environment_scope: 'production') }

        context 'when filter[environment_scope] is not passed' do
          it 'returns 409' do
            get api("/projects/#{project.id}/variables/key1", user)

            expect(response).to have_gitlab_http_status(:conflict)
          end
        end

        context 'when filter[environment_scope] is passed' do
          it 'updates the variable' do
            put api("/projects/#{project.id}/variables/key1", user), params: { value: 'new_val', 'filter[environment_scope]': 'production' }

            expect(response).to have_gitlab_http_status(:ok)
            expect(var1.reload.value).not_to eq('new_val')
            expect(var2.reload.value).to eq('new_val')
          end
        end

        context 'when wrong filter[environment_scope] is passed' do
          it 'returns not_found' do
            put api("/projects/#{project.id}/variables/key1", user), params: { value: 'new_val', 'filter[environment_scope]': 'invalid' }

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end
    end

    context 'authorized user with invalid permissions' do
      it 'does not update variable' do
        put api("/projects/#{project.id}/variables/#{variable.key}", user2)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'unauthorized user' do
      it 'does not update variable' do
        put api("/projects/#{project.id}/variables/#{variable.key}")

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  describe 'DELETE /projects/:id/variables/:key' do
    context 'authorized user with proper permissions' do
      it 'deletes variable' do
        expect do
          delete api("/projects/#{project.id}/variables/#{variable.key}", user)

          expect(response).to have_gitlab_http_status(:no_content)
        end.to change { project.variables.count }.by(-1)
      end

      it 'responds with 404 Not Found if requesting non-existing variable' do
        delete api("/projects/#{project.id}/variables/non_existing_variable", user)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      context 'when there are two variables with the same key on different env' do
        let!(:var1) { create(:ci_variable, project: project, key: 'key1', environment_scope: 'staging') }
        let!(:var2) { create(:ci_variable, project: project, key: 'key1', environment_scope: 'production') }

        context 'when filter[environment_scope] is not passed' do
          it 'returns 409' do
            get api("/projects/#{project.id}/variables/key1", user)

            expect(response).to have_gitlab_http_status(:conflict)
          end
        end

        context 'when filter[environment_scope] is passed' do
          it 'deletes the variable' do
            expect do
              delete api("/projects/#{project.id}/variables/key1", user), params: { 'filter[environment_scope]': 'production' }

              expect(response).to have_gitlab_http_status(:no_content)
            end.to change { project.variables.count }.by(-1)

            expect(var1.reload).to be_present
            expect { var2.reload }.to raise_error(ActiveRecord::RecordNotFound)
          end
        end

        context 'when wrong filter[environment_scope] is passed' do
          it 'returns not_found' do
            delete api("/projects/#{project.id}/variables/key1", user), params: { 'filter[environment_scope]': 'invalid' }

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end
    end

    context 'authorized user with invalid permissions' do
      it 'does not delete variable' do
        delete api("/projects/#{project.id}/variables/#{variable.key}", user2)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'unauthorized user' do
      it 'does not delete variable' do
        delete api("/projects/#{project.id}/variables/#{variable.key}")

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end
end
