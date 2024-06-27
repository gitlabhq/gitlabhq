# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ProjectContainerRegistryProtectionRules, feature_category: :container_registry do
  include ExclusiveLeaseHelpers

  let_it_be(:project) { create(:project, :private) }
  let_it_be(:other_project) { create(:project, :private) }
  let_it_be(:container_registry_protection_rule) { create(:container_registry_protection_rule, project: project) }

  let_it_be(:maintainer) { create(:user, maintainer_of: [project, other_project]) }
  let_it_be(:api_user) { create(:user) }

  let_it_be(:invalid_token) { 'invalid-token123' }
  let_it_be(:headers_with_invalid_token) { { Gitlab::Auth::AuthFinders::PRIVATE_TOKEN_HEADER => invalid_token } }

  shared_examples 'rejecting project container protection rules request' do
    using RSpec::Parameterized::TableSyntax

    where(:user_role, :status) do
      :reporter  | :forbidden
      :developer | :forbidden
      :guest     | :forbidden
      nil        | :not_found
    end

    with_them do
      before do
        project.send(:"add_#{user_role}", api_user) if user_role
      end

      it_behaves_like 'returning response status', params[:status]
    end
  end

  describe 'GET /projects/:id/registry/protection/rules' do
    let(:url) { "/projects/#{project.id}/registry/protection/rules" }

    subject(:get_container_registry_rules) { get(api(url, api_user)) }

    context 'when not enough permissions' do
      it_behaves_like 'rejecting project container protection rules request'
    end

    context 'for maintainer' do
      let(:api_user) { maintainer }

      context 'with multiple container protection rules' do
        let_it_be(:other_container_registry_protection_rule) do
          create(:container_registry_protection_rule,
            project: project,
            repository_path_pattern: "#{container_registry_protection_rule.repository_path_pattern}-unique")
        end

        it 'gets the container registry protection rules', :aggregate_failures do
          get_container_registry_rules

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response.count).to eq(2)
          expect(json_response.pluck('id')).to match_array([container_registry_protection_rule.id,
            other_container_registry_protection_rule.id])
        end
      end

      it 'contains the content of a container registry protection rule', :aggregate_failures do
        get_container_registry_rules

        expect(json_response.first).to include(
          'project_id' => container_registry_protection_rule.project.id,
          'repository_path_pattern' => container_registry_protection_rule.repository_path_pattern,
          'minimum_access_level_for_push' => container_registry_protection_rule.minimum_access_level_for_push,
          'minimum_access_level_for_delete' => container_registry_protection_rule.minimum_access_level_for_delete
        )
      end

      context 'when the project id is invalid' do
        let(:url) { '/projects/invalid/registry/protection/rules' }

        it_behaves_like 'returning response status', :not_found
      end

      context 'when the project id does not exist' do
        let(:url) { "/projects/#{non_existing_record_id}/registry/protection/rules" }

        it_behaves_like 'returning response status', :not_found
      end

      context 'when container_registry_protected_containers is disabled' do
        before do
          stub_feature_flags(container_registry_protected_containers: false)
        end

        it_behaves_like 'returning response status', :not_found
      end
    end

    context 'with invalid token' do
      subject(:get_container_registry_rules) { get(api(url), headers: headers_with_invalid_token) }

      it_behaves_like 'returning response status', :unauthorized
    end
  end
end
