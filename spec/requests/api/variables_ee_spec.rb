require 'spec_helper'

describe API::Variables do
  let(:user) { create(:user) }
  let(:project) { create(:empty_project) }

  describe 'POST /projects/:id/variables' do
    context 'with variable environment scope available' do
      before do
        stub_licensed_features(variable_environment_scope: true)

        project.add_master(user)
      end

      it 'creates variable with a specific environment scope' do
        expect do
          post api("/projects/#{project.id}/variables", user), key: 'TEST_VARIABLE_2', value: 'VALUE_2', environment_scope: 'review/*'
        end.to change { project.variables(true).count }.by(1)

        expect(response).to have_http_status(201)
        expect(json_response['key']).to eq('TEST_VARIABLE_2')
        expect(json_response['value']).to eq('VALUE_2')
        expect(json_response['environment_scope']).to eq('review/*')
      end

      it 'allows duplicated variable key given different environment scopes' do
        variable = create(:ci_variable, project: project)

        expect do
          post api("/projects/#{project.id}/variables", user), key: variable.key, value: 'VALUE_2', environment_scope: 'review/*'
        end.to change { project.variables(true).count }.by(1)

        expect(response).to have_http_status(201)
        expect(json_response['key']).to eq(variable.key)
        expect(json_response['value']).to eq('VALUE_2')
        expect(json_response['environment_scope']).to eq('review/*')
      end
    end
  end
end
