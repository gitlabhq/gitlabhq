# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ProjectContainerRegistryProtectionRules, :aggregate_failures, feature_category: :container_registry do
  let_it_be(:project) { create(:project, :private) }
  let_it_be(:other_project) { create(:project, :private) }
  let_it_be(:protection_rule) { create(:container_registry_protection_rule, project: project) }
  let_it_be(:protection_rule_id) { protection_rule.id }

  let_it_be(:maintainer) { create(:user, maintainer_of: [project, other_project]) }
  let_it_be(:api_user) { create(:user) }

  let_it_be(:invalid_token) { 'invalid-token123' }
  let_it_be(:headers_with_invalid_token) { { Gitlab::Auth::AuthFinders::PRIVATE_TOKEN_HEADER => invalid_token } }

  let(:path) { 'registry/protection/repository/rules' }
  let(:url) { "/projects/#{project.id}/#{path}" }

  let(:params) do
    { repository_path_pattern: "#{protection_rule.repository_path_pattern}-unique",
      minimum_access_level_for_push: protection_rule.minimum_access_level_for_push,
      minimum_access_level_for_delete: protection_rule.minimum_access_level_for_delete }
  end

  shared_examples 'rejecting container registry protection rules request when enough permissions' do
    it_behaves_like 'rejecting protection rules request when invalid project'
  end

  describe 'GET /projects/:id/registry/protection/repository/rules' do
    subject(:get_container_registry_rules) { get(api(url, api_user)) }

    it_behaves_like 'rejecting project protection rules request when not enough permissions'

    context 'for maintainer' do
      let(:api_user) { maintainer }

      context 'with multiple container protection rules' do
        let_it_be(:other_container_registry_protection_rule) do
          create(:container_registry_protection_rule,
            project: project,
            repository_path_pattern: "#{protection_rule.repository_path_pattern}-unique")
        end

        it 'gets the container registry protection rules', :aggregate_failures do
          get_container_registry_rules

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response.count).to eq(2)
          expect(json_response.pluck('id')).to match_array([protection_rule.id,
            other_container_registry_protection_rule.id])
        end
      end

      it 'contains the content of a container registry protection rule', :aggregate_failures do
        get_container_registry_rules

        expect(json_response.first).to include(
          'project_id' => protection_rule.project.id,
          'repository_path_pattern' => protection_rule.repository_path_pattern,
          'minimum_access_level_for_push' => protection_rule.minimum_access_level_for_push,
          'minimum_access_level_for_delete' => protection_rule.minimum_access_level_for_delete
        )
      end

      it_behaves_like 'rejecting container registry protection rules request when enough permissions'
    end

    context 'with invalid token' do
      subject(:get_container_registry_rules) { get(api(url), headers: headers_with_invalid_token) }

      it_behaves_like 'returning response status', :unauthorized
    end
  end

  describe 'POST /projects/:id/registry/protection/repository/rules' do
    subject(:post_container_registry_rule) { post(api(url, api_user), params: params) }

    it_behaves_like 'rejecting project protection rules request when not enough permissions'

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
          params[:repository_path_pattern] = protection_rule.repository_path_pattern
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

  describe 'PATCH /projects/:id/registry/protection/repository/rules/:protection_rule_id' do
    let(:path) { "registry/protection/repository/rules/#{protection_rule_id}" }

    subject(:patch_container_registry_protection_rule) { patch(api(url, api_user), params: params) }

    it_behaves_like 'rejecting project protection rules request when not enough permissions'

    context 'for maintainer' do
      let(:api_user) { maintainer }
      let_it_be(:changed_repository_path_pattern) do
        "#{protection_rule.repository_path_pattern}-changed"
      end

      context 'with full changeset' do
        before do
          params[:repository_path_pattern] = changed_repository_path_pattern
        end

        it 'updates a container registry protection rule' do
          patch_container_registry_protection_rule
          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to match(hash_including({
            'project_id' => protection_rule.project.id,
            'repository_path_pattern' => changed_repository_path_pattern,
            'minimum_access_level_for_push' => protection_rule.minimum_access_level_for_push,
            'minimum_access_level_for_delete' => protection_rule.minimum_access_level_for_delete
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

      it_behaves_like 'rejecting protection rules request when handling rule ids'
      it_behaves_like 'rejecting container registry protection rules request when enough permissions'
    end

    context 'with invalid token' do
      subject(:patch_container_registry_protection_rule) do
        patch(api(url), headers: headers_with_invalid_token, params: params)
      end

      it_behaves_like 'returning response status', :unauthorized
    end
  end

  describe 'DELETE /projects/:id/registry/protection/repository/rules/:protection_rule_id' do
    let(:path) { "registry/protection/repository/rules/#{protection_rule_id}" }

    subject(:delete_protection_rule) { delete(api(url, api_user)) }

    it_behaves_like 'rejecting project protection rules request when not enough permissions'

    context 'for maintainer' do
      let(:api_user) { maintainer }

      it 'deletes the container registry protection rule' do
        delete_protection_rule
        expect do
          ContainerRegistry::Protection::Rule.find(protection_rule.id)
        end.to raise_error(ActiveRecord::RecordNotFound)
        expect(response).to have_gitlab_http_status(:no_content)
      end

      it_behaves_like 'rejecting protection rules request when handling rule ids'
      it_behaves_like 'rejecting container registry protection rules request when enough permissions'
    end

    context 'with invalid token' do
      subject(:delete_protection_rules) { delete(api(url), headers: headers_with_invalid_token) }

      it_behaves_like 'returning response status', :unauthorized
    end
  end
end
