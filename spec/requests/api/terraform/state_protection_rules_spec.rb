# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Terraform::StateProtectionRules, :aggregate_failures,
  feature_category: :infrastructure_as_code do
  let_it_be(:project) { create(:project, :private) }
  let_it_be(:other_project) { create(:project, :private) }
  let_it_be_with_reload(:protection_rule) do
    create(:terraform_state_protection_rule, project: project,
      state_name: 'production',
      minimum_access_level_for_write: :maintainer,
      allowed_from: :ci_only)
  end

  let_it_be(:developer) { create(:user, developer_of: project) }
  let_it_be(:maintainer) { create(:user, maintainer_of: [project, other_project]) }
  let_it_be(:api_user) { create(:user) }

  let_it_be(:invalid_token) { 'invalid-token123' }
  let_it_be(:headers_with_invalid_token) do
    { Gitlab::Auth::AuthFinders::PRIVATE_TOKEN_HEADER => invalid_token }
  end

  let(:protection_rule_id) { protection_rule.id }
  let(:path) { 'terraform/state_protection_rules' }
  let(:url) { "/projects/#{project.id}/#{path}" }

  describe 'GET /projects/:id/terraform/state_protection_rules' do
    subject(:get_protection_rules) { get(api(url, api_user)) }

    context 'when user does not have read_terraform_state permission' do
      context 'with reporter access' do
        let(:api_user) { create(:user, reporter_of: project) }

        it_behaves_like 'returning response status', :forbidden
      end

      context 'with guest access' do
        let(:api_user) { create(:user, guest_of: project) }

        it_behaves_like 'returning response status', :forbidden
      end

      context 'with no project access' do
        it_behaves_like 'returning response status', :not_found
      end
    end

    context 'for developer' do
      let(:api_user) { developer }

      let_it_be(:other_protection_rule) do
        create(:terraform_state_protection_rule, project: project,
          state_name: 'staging',
          minimum_access_level_for_write: :developer,
          allowed_from: :anywhere)
      end

      it 'gets the terraform state protection rules' do
        get_protection_rules

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.count).to eq(2)
        expect(json_response).to include(
          hash_including(
            'id' => protection_rule.id,
            'project_id' => project.id,
            'state_name' => 'production',
            'minimum_access_level_for_write' => 'maintainer',
            'allowed_from' => 'ci_only'
          )
        )
      end

      it_behaves_like 'rejecting protection rules request when invalid project'
    end

    context 'for maintainer' do
      let(:api_user) { maintainer }

      it 'gets the terraform state protection rules' do
        get_protection_rules

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'when feature flag :protected_terraform_states is disabled' do
      let(:api_user) { maintainer }

      before do
        stub_feature_flags(protected_terraform_states: false)
      end

      it_behaves_like 'returning response status', :not_found
    end

    context 'with invalid token' do
      subject(:get_protection_rules) { get(api(url), headers: headers_with_invalid_token) }

      it_behaves_like 'returning response status', :unauthorized
    end

    it_behaves_like 'authorizing granular token permissions', :read_terraform_state do
      let(:user) { developer }
      let(:boundary_object) { project }
      let(:request) { get api(url, personal_access_token: pat) }
    end
  end

  describe 'POST /projects/:id/terraform/state_protection_rules' do
    let(:params) do
      {
        state_name: 'staging',
        minimum_access_level_for_write: 'maintainer',
        allowed_from: 'ci_only'
      }
    end

    subject(:post_protection_rule) { post(api(url, api_user), params: params) }

    it_behaves_like 'rejecting project protection rules request when not enough permissions'

    context 'for maintainer' do
      let(:api_user) { maintainer }

      it 'creates a terraform state protection rule' do
        expect { post_protection_rule }.to change { Terraform::StateProtectionRule.count }.by(1)
        expect(response).to have_gitlab_http_status(:created)

        expect(json_response).to include(
          'id' => Integer,
          'project_id' => project.id,
          'state_name' => 'staging',
          'minimum_access_level_for_write' => 'maintainer',
          'allowed_from' => 'ci_only'
        )
      end

      context 'without allowed_from (defaults to anywhere)' do
        let(:params) { super().except(:allowed_from) }

        it 'creates the rule with default allowed_from' do
          expect { post_protection_rule }.to change { Terraform::StateProtectionRule.count }.by(1)
          expect(response).to have_gitlab_http_status(:created)
          expect(json_response['allowed_from']).to eq('anywhere')
        end
      end

      context 'with invalid minimum_access_level_for_write' do
        let(:params) { super().merge(minimum_access_level_for_write: 'not_valid') }

        it_behaves_like 'returning response status', :bad_request
      end

      context 'with invalid allowed_from' do
        let(:params) { super().merge(allowed_from: 'not_valid') }

        it_behaves_like 'returning response status', :bad_request
      end

      context 'without state_name' do
        let(:params) { super().except(:state_name) }

        it_behaves_like 'returning response status', :bad_request
      end

      context 'with state_name exceeding 255 characters' do
        let(:params) { super().merge(state_name: 'a' * 256) }

        it_behaves_like 'returning response status', :bad_request
      end

      context 'without minimum_access_level_for_write' do
        let(:params) { super().except(:minimum_access_level_for_write) }

        it_behaves_like 'returning response status', :bad_request
      end

      context 'with already existing state_name for same project' do
        let(:params) { super().merge(state_name: protection_rule.state_name) }

        it 'does not create a protection rule' do
          expect { post_protection_rule }.not_to change { Terraform::StateProtectionRule.count }
          expect(response).to have_gitlab_http_status(:unprocessable_entity)
        end
      end

      it_behaves_like 'rejecting protection rules request when invalid project'
    end

    context 'when feature flag is disabled' do
      let(:api_user) { maintainer }

      before do
        stub_feature_flags(protected_terraform_states: false)
      end

      it 'does not create a protection rule' do
        expect { post_protection_rule }.not_to change { Terraform::StateProtectionRule.count }
      end

      it_behaves_like 'returning response status', :not_found
    end

    context 'with invalid token' do
      subject(:post_protection_rule) { post(api(url), headers: headers_with_invalid_token, params: params) }

      it_behaves_like 'returning response status', :unauthorized
    end

    it_behaves_like 'authorizing granular token permissions', :create_terraform_state_protection_rule do
      let(:user) { maintainer }
      let(:boundary_object) { project }
      let(:request) { post api(url, personal_access_token: pat), params: params }
    end
  end

  describe 'PATCH /projects/:id/terraform/state_protection_rules/:terraform_state_protection_rule_id' do
    let(:path) { "terraform/state_protection_rules/#{protection_rule_id}" }

    let(:params) do
      {
        state_name: 'staging',
        minimum_access_level_for_write: 'owner',
        allowed_from: 'ci_on_protected_branch_only'
      }
    end

    subject(:patch_protection_rule) { patch(api(url, api_user), params: params) }

    it_behaves_like 'rejecting project protection rules request when not enough permissions'

    context 'for maintainer' do
      let(:api_user) { maintainer }

      context 'with full changeset' do
        it 'updates the terraform state protection rule' do
          patch_protection_rule

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to include(
            'state_name' => 'staging',
            'minimum_access_level_for_write' => 'owner',
            'allowed_from' => 'ci_on_protected_branch_only'
          )
        end
      end

      context 'with a single change' do
        let(:params) { { minimum_access_level_for_write: 'owner' } }

        it 'updates only the specified field' do
          patch_protection_rule

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['minimum_access_level_for_write']).to eq('owner')
          expect(json_response['state_name']).to eq(protection_rule.state_name)
          expect(json_response['allowed_from']).to eq(protection_rule.allowed_from)
        end
      end

      context 'with invalid minimum_access_level_for_write' do
        let(:params) { super().merge(minimum_access_level_for_write: 'not_valid') }

        it_behaves_like 'returning response status', :bad_request
      end

      context 'with invalid allowed_from' do
        let(:params) { super().merge(allowed_from: 'not_valid') }

        it_behaves_like 'returning response status', :bad_request
      end

      context 'with duplicate state_name' do
        let_it_be(:existing_rule) do
          create(:terraform_state_protection_rule, project: project, state_name: 'staging')
        end

        let(:params) { { state_name: 'staging' } }

        it_behaves_like 'returning response status', :unprocessable_entity
      end

      it_behaves_like 'rejecting protection rules request when handling rule ids'
      it_behaves_like 'rejecting protection rules request when invalid project'
    end

    context 'when feature flag :protected_terraform_states is disabled' do
      let(:api_user) { maintainer }

      before do
        stub_feature_flags(protected_terraform_states: false)
      end

      it 'does not update the rule' do
        expect { patch_protection_rule }.not_to change { protection_rule.reload.updated_at }
      end

      it_behaves_like 'returning response status', :not_found
    end

    context 'with invalid token' do
      subject(:patch_protection_rule) { patch(api(url), headers: headers_with_invalid_token, params: params) }

      it_behaves_like 'returning response status', :unauthorized
    end

    it_behaves_like 'authorizing granular token permissions', :update_terraform_state_protection_rule do
      let(:user) { maintainer }
      let(:boundary_object) { project }
      let(:request) { patch api(url, personal_access_token: pat), params: params }
    end
  end

  describe 'DELETE /projects/:id/terraform/state_protection_rules/:terraform_state_protection_rule_id' do
    let(:path) { "terraform/state_protection_rules/#{protection_rule_id}" }

    subject(:destroy_protection_rule) { delete(api(url, api_user)) }

    it_behaves_like 'rejecting project protection rules request when not enough permissions'

    context 'for maintainer' do
      let(:api_user) { maintainer }

      it 'deletes the terraform state protection rule' do
        destroy_protection_rule

        expect(response).to have_gitlab_http_status(:no_content)
        expect { protection_rule.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it_behaves_like 'rejecting protection rules request when handling rule ids'
      it_behaves_like 'rejecting protection rules request when invalid project'
    end

    context 'when feature flag :protected_terraform_states is disabled' do
      let(:api_user) { maintainer }

      before do
        stub_feature_flags(protected_terraform_states: false)
      end

      it 'does not delete the rule' do
        expect { destroy_protection_rule }.not_to change { Terraform::StateProtectionRule.count }
      end

      it_behaves_like 'returning response status', :not_found
    end

    context 'with invalid token' do
      subject(:destroy_protection_rule) { delete(api(url), headers: headers_with_invalid_token) }

      it_behaves_like 'returning response status', :unauthorized
    end

    it_behaves_like 'authorizing granular token permissions', :delete_terraform_state_protection_rule do
      let(:user) { maintainer }
      let(:boundary_object) { project }
      let(:request) { delete api(url, personal_access_token: pat) }
    end
  end
end
