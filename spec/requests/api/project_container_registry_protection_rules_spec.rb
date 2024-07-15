# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ProjectContainerRegistryProtectionRules, :aggregate_failures, feature_category: :container_registry do
  include ExclusiveLeaseHelpers

  let_it_be(:project) { create(:project, :private) }
  let_it_be(:other_project) { create(:project, :private) }
  let_it_be(:container_registry_protection_rule) { create(:container_registry_protection_rule, project: project) }

  let_it_be(:maintainer) { create(:user, maintainer_of: [project, other_project]) }
  let_it_be(:api_user) { create(:user) }

  let_it_be(:invalid_token) { 'invalid-token123' }
  let_it_be(:headers_with_invalid_token) { { Gitlab::Auth::AuthFinders::PRIVATE_TOKEN_HEADER => invalid_token } }

  let(:params) do
    { repository_path_pattern: "#{container_registry_protection_rule.repository_path_pattern}-unique",
      minimum_access_level_for_push: container_registry_protection_rule.minimum_access_level_for_push,
      minimum_access_level_for_delete: container_registry_protection_rule.minimum_access_level_for_delete }
  end

  shared_examples 'rejecting project container protection rules request when not enough permissions' do
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

  shared_examples 'rejecting container registry protection rules request when enough permissions' do
    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(container_registry_protected_containers: false)
      end

      it_behaves_like 'returning response status', :not_found
    end

    context 'when the project id is invalid' do
      let(:url) { "/projects/invalid/registry/protection/rules" }

      it_behaves_like 'returning response status', :not_found
    end

    context 'when the project id does not exist' do
      let(:url) { "/projects/#{non_existing_record_id}/registry/protection/rules" }

      it_behaves_like 'returning response status', :not_found
    end
  end

  shared_examples 'rejecting container registry protection rules request when handling rule ids' do
    context 'when the rule id is invalid' do
      let(:url) { "/projects/#{project.id}/registry/protection/rules/invalid" }

      it_behaves_like 'returning response status', :bad_request
    end

    context 'when the rule id does not exist' do
      let(:url) { "/projects/#{project.id}/registry/protection/rules/#{non_existing_record_id}" }

      it_behaves_like 'returning response status', :not_found
    end

    context 'when the container registry protection rule does belong to another project' do
      let(:url) { "/projects/#{other_project.id}/registry/protection/rules/#{container_registry_protection_rule.id}" }

      it_behaves_like 'returning response status', :not_found
    end
  end

  describe 'GET /projects/:id/registry/protection/rules' do
    let(:url) { "/projects/#{project.id}/registry/protection/rules" }

    subject(:get_container_registry_rules) { get(api(url, api_user)) }

    it_behaves_like 'rejecting project container protection rules request when not enough permissions'

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

      it_behaves_like 'rejecting container registry protection rules request when enough permissions'
    end

    context 'with invalid token' do
      subject(:get_container_registry_rules) { get(api(url), headers: headers_with_invalid_token) }

      it_behaves_like 'returning response status', :unauthorized
    end
  end

  describe 'POST /projects/:id/registry/protection/rules' do
    let(:url) { "/projects/#{project.id}/registry/protection/rules" }

    subject(:post_container_registry_rule) { post(api(url, api_user), params: params) }

    it_behaves_like 'rejecting project container protection rules request when not enough permissions'

    context 'for maintainer' do
      let(:api_user) { maintainer }

      it 'creates a container registry protection rule' do
        expect { post_container_registry_rule }.to change { ContainerRegistry::Protection::Rule.count }.by(1)
        expect(response).to have_gitlab_http_status(:created)
      end

      context 'with empty minimum_access_level_for_push' do
        before do
          params[:minimum_access_level_for_push] = nil
        end

        it 'creates a container registry protection rule' do
          expect { post_container_registry_rule }.to change { ContainerRegistry::Protection::Rule.count }.by(1)
          expect(response).to have_gitlab_http_status(:created)
        end
      end

      context 'with invalid minimum_access_level_for_delete' do
        before do
          params[:minimum_access_level_for_delete] = "not in enum"
        end

        it 'does not create a container registry protection rule' do
          expect { post_container_registry_rule }.to not_change(ContainerRegistry::Protection::Rule, :count)
          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end

      context 'with empty minimum_access_level_for_delete' do
        before do
          params[:minimum_access_level_for_delete] = nil
        end

        it 'creates a container registry protection rule' do
          expect { post_container_registry_rule }.to change { ContainerRegistry::Protection::Rule.count }.by(1)
          expect(response).to have_gitlab_http_status(:created)
        end
      end

      context 'with invalid minimum_access_level_for_push' do
        before do
          params[:minimum_access_level_for_push] = "not in enum"
        end

        it 'does not create a container registry protection rule' do
          expect { post_container_registry_rule }.to not_change(ContainerRegistry::Protection::Rule, :count)
          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end

      context 'with already existing repository_path_pattern' do
        before do
          params[:repository_path_pattern] = container_registry_protection_rule.repository_path_pattern
        end

        it 'does not create a container registry protection rule' do
          expect { post_container_registry_rule }.to not_change(ContainerRegistry::Protection::Rule, :count)
          expect(response).to have_gitlab_http_status(:unprocessable_entity)
        end
      end

      context 'with neither minimum_access_level_for_push nor minimum_access_level_for_delete' do
        before do
          params[:minimum_access_level_for_push] = nil
          params[:minimum_access_level_for_delete] = nil
        end

        it 'does not create a container registry protection rule' do
          expect { post_container_registry_rule }.to not_change(ContainerRegistry::Protection::Rule, :count)
          expect(response).to have_gitlab_http_status(:unprocessable_entity)
        end
      end

      it_behaves_like 'rejecting container registry protection rules request when enough permissions'
    end

    context 'with invalid token' do
      subject(:post_container_registry_rules) { post(api(url), headers: headers_with_invalid_token, params: params) }

      it_behaves_like 'returning response status', :unauthorized
    end
  end

  describe 'PATCH /projects/:id/registry/protection/rules/:protection_rule_id' do
    let(:url) { "/projects/#{project.id}/registry/protection/rules/#{container_registry_protection_rule.id}" }

    subject(:patch_container_registry_protection_rule) { patch(api(url, api_user), params: params) }

    it_behaves_like 'rejecting project container protection rules request when not enough permissions'

    context 'for maintainer' do
      let(:api_user) { maintainer }
      let_it_be(:changed_repository_path_pattern) do
        "#{container_registry_protection_rule.repository_path_pattern}-changed"
      end

      context 'with full changeset' do
        before do
          params[:repository_path_pattern] = changed_repository_path_pattern
        end

        it 'updates a container registry protection rule' do
          patch_container_registry_protection_rule
          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to match(hash_including({
            'project_id' => container_registry_protection_rule.project.id,
            'repository_path_pattern' => changed_repository_path_pattern,
            'minimum_access_level_for_push' => container_registry_protection_rule.minimum_access_level_for_push,
            'minimum_access_level_for_delete' => container_registry_protection_rule.minimum_access_level_for_delete
          }))
        end
      end

      context 'with a single change' do
        let(:params) { { repository_path_pattern: changed_repository_path_pattern } }

        it 'updates a container registry protection rule' do
          patch_container_registry_protection_rule

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response["repository_path_pattern"]).to eq(changed_repository_path_pattern)
        end
      end

      context 'with minimum_access_level_to_push set to nil' do
        before do
          params[:minimum_access_level_for_push] = ""
        end

        it 'clears the minimum_access_level_to_push' do
          patch_container_registry_protection_rule

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response["minimum_access_level_for_push"]).to be_nil
        end

        context 'with minimum_access_level_to_delete set to nil as well' do
          before do
            params[:minimum_access_level_for_delete] = ""
          end

          it_behaves_like 'returning response status', :unprocessable_entity
        end
      end

      context 'with minimum_access_level_to_delete set to nil' do
        before do
          params[:minimum_access_level_for_delete] = ""
        end

        it 'clears the minimum_access_level_to_delete' do
          patch_container_registry_protection_rule

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response["minimum_access_level_for_delete"]).to be_nil
        end

        context 'with minimum_access_level_to_push set to nil as well' do
          before do
            params[:minimum_access_level_for_push] = ""
          end

          it_behaves_like 'returning response status', :unprocessable_entity
        end
      end

      context 'with invalid repository_path_pattern' do
        before do
          params[:repository_path_pattern] = "not in enum"
        end

        it_behaves_like 'returning response status', :unprocessable_entity
      end

      context 'with invalid minimum_access_level_for_push' do
        before do
          params[:minimum_access_level_for_push] = "not in enum"
        end

        it_behaves_like 'returning response status', :bad_request
      end

      context 'with already existing repository_path_pattern' do
        before do
          other_protection_rule = create(:container_registry_protection_rule, project: project,
            repository_path_pattern: "#{project.full_path}/path")
          params[:repository_path_pattern] = other_protection_rule.repository_path_pattern
        end

        it_behaves_like 'returning response status', :unprocessable_entity
      end

      it_behaves_like 'rejecting container registry protection rules request when handling rule ids'
      it_behaves_like 'rejecting container registry protection rules request when enough permissions'
    end

    context 'with invalid token' do
      subject(:patch_container_registry_protection_rule) do
        patch(api(url), headers: headers_with_invalid_token, params: params)
      end

      it_behaves_like 'returning response status', :unauthorized
    end
  end
end
