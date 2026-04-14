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

  shared_examples 'rejecting terraform state protection rules request when enough permissions' do
    it_behaves_like 'rejecting protection rules request when invalid project'
  end

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

      it_behaves_like 'rejecting terraform state protection rules request when enough permissions'
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
end
