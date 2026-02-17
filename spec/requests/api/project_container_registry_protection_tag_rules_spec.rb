# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ProjectContainerRegistryProtectionTagRules, :aggregate_failures,
  feature_category: :container_registry do
  include ContainerRegistryHelpers

  let_it_be(:project) { create(:project, :private) }
  let_it_be(:other_project) { create(:project, :private) }
  let_it_be(:tag_rule) do
    create(:container_registry_protection_tag_rule, project: project, tag_name_pattern: 'v*')
  end

  let_it_be(:maintainer) { create(:user, maintainer_of: [project, other_project]) }
  let_it_be(:admin) { create(:admin) }
  let_it_be(:api_user) { create(:user) }

  let_it_be(:invalid_token) { 'invalid-token123' }
  let_it_be(:headers_with_invalid_token) { { Gitlab::Auth::AuthFinders::PRIVATE_TOKEN_HEADER => invalid_token } }

  let(:path) { 'registry/protection/tag/rules' }
  let(:url) { "/projects/#{project.id}/#{path}" }

  describe 'GET /projects/:id/registry/protection/tag/rules' do
    let_it_be(:path) { 'registry/protection/tag/rules' }
    let_it_be(:url) { "/projects/#{project.id}/#{path}" }

    subject(:get_tag_rules) { get(api(url, api_user)) }

    shared_examples 'returning tag protection rules' do
      let(:expected_tag_rules) do
        [
          a_hash_including(
            'id' => tag_rule.id,
            'project_id' => project.id,
            'tag_name_pattern' => 'v*',
            'minimum_access_level_for_push' => 'maintainer',
            'minimum_access_level_for_delete' => 'maintainer'
          )
        ]
      end

      it 'returns list of tag protection rules' do
        get_tag_rules

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to match_array(expected_tag_rules)
      end
    end

    it_behaves_like 'rejecting project protection rules request when not enough permissions'

    context 'for maintainer' do
      let(:api_user) { maintainer }

      it_behaves_like 'returning tag protection rules'

      context 'when no rules exist' do
        before do
          tag_rule.destroy!
        end

        it_behaves_like 'returning tag protection rules' do
          let(:expected_tag_rules) { [] }
        end
      end

      context 'with multiple tag rules' do
        let_it_be(:other_tag_rule) do
          create(:container_registry_protection_tag_rule, project: project, tag_name_pattern: 'release-*')
        end

        it_behaves_like 'returning tag protection rules' do
          let(:expected_tag_rules) do
            [
              a_hash_including('id' => tag_rule.id),
              a_hash_including('id' => other_tag_rule.id)
            ]
          end
        end
      end

      it_behaves_like 'rejecting protection rules request when invalid project'
    end

    context 'for admin' do
      subject(:get_tag_rules) { get(api(url, admin, admin_mode: true)) }

      it_behaves_like 'returning tag protection rules'
    end

    context 'with invalid token' do
      subject(:get_tag_rules) { get(api(url), headers: headers_with_invalid_token) }

      it_behaves_like 'returning response status', :unauthorized
    end
  end

  describe 'POST /projects/:id/registry/protection/tag/rules' do
    let(:path) { 'registry/protection/tag/rules' }
    let(:url) { "/projects/#{project.id}/#{path}" }

    let(:params) do
      {
        tag_name_pattern: 'release-*',
        minimum_access_level_for_push: 'maintainer',
        minimum_access_level_for_delete: 'owner'
      }
    end

    subject(:post_tag_rule) { post(api(url, api_user), params: params) }

    before do
      stub_gitlab_api_client_to_support_gitlab_api(supported: true)
    end

    shared_examples 'allowed to create tag protection rule' do
      it 'creates a tag protection rule' do
        expect { post_tag_rule }.to change { ContainerRegistry::Protection::TagRule.count }.by(1)

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response).to include(
          'tag_name_pattern' => 'release-*',
          'minimum_access_level_for_push' => 'maintainer',
          'minimum_access_level_for_delete' => 'owner'
        )
      end

      context 'with missing tag_name_pattern' do
        let(:params) { super().except(:tag_name_pattern) }

        it_behaves_like 'not creating a tag protection rule', :bad_request
      end

      context 'with missing minimum_access_level_for_push' do
        let(:params) { super().except(:minimum_access_level_for_push) }

        it_behaves_like 'not creating a tag protection rule', :bad_request
      end

      context 'with missing minimum_access_level_for_delete' do
        let(:params) { super().except(:minimum_access_level_for_delete) }

        it_behaves_like 'not creating a tag protection rule', :bad_request
      end

      context 'with invalid minimum_access_level_for_push' do
        let(:params) { super().merge(minimum_access_level_for_push: 'invalid_role') }

        it_behaves_like 'not creating a tag protection rule', :bad_request
      end

      context 'with invalid minimum_access_level_for_delete' do
        let(:params) { super().merge(minimum_access_level_for_delete: 'invalid_role') }

        it_behaves_like 'not creating a tag protection rule', :bad_request
      end

      context 'with already existing tag_name_pattern' do
        let(:params) { super().merge(tag_name_pattern: tag_rule.tag_name_pattern) }

        it_behaves_like 'not creating a tag protection rule', :unprocessable_entity
      end

      context 'when the GitLab API is not supported' do
        before do
          stub_gitlab_api_client_to_support_gitlab_api(supported: false)
        end

        it_behaves_like 'not creating a tag protection rule', :unprocessable_entity

        it 'returns error message' do
          post_tag_rule

          expect(json_response).to eq({ 'message' => 'GitLab container registry API not supported' })
        end
      end

      it_behaves_like 'rejecting protection rules request when invalid project'
    end

    shared_examples 'not creating a tag protection rule' do |status|
      it "does not create a tag protection rule and returns #{status}" do
        expect { post_tag_rule }.to not_change(ContainerRegistry::Protection::TagRule, :count)

        expect(response).to have_gitlab_http_status(status)
      end
    end

    it_behaves_like 'rejecting project protection rules request when not enough permissions'

    context 'for maintainer' do
      let(:api_user) { maintainer }

      it_behaves_like 'allowed to create tag protection rule'
    end

    context 'for admin' do
      subject(:post_tag_rule) { post(api(url, admin, admin_mode: true), params: params) }

      it_behaves_like 'allowed to create tag protection rule'
    end

    context 'with invalid token' do
      subject(:post_tag_rule) { post(api(url), headers: headers_with_invalid_token, params: params) }

      it_behaves_like 'returning response status', :unauthorized
    end
  end

  describe 'PATCH /projects/:id/registry/protection/tag/rules/:protection_rule_id' do
    let_it_be_with_reload(:tag_rule_to_update) do
      create(:container_registry_protection_tag_rule,
        project: project,
        tag_name_pattern: 'original-*',
        minimum_access_level_for_push: :maintainer,
        minimum_access_level_for_delete: :maintainer)
    end

    let(:protection_rule) { tag_rule_to_update }
    let(:protection_rule_id) { tag_rule_to_update.id }
    let(:path) { "registry/protection/tag/rules/#{protection_rule_id}" }

    let(:params) do
      {
        tag_name_pattern: 'updated-*',
        minimum_access_level_for_push: 'owner',
        minimum_access_level_for_delete: 'admin'
      }
    end

    subject(:patch_tag_rule) { patch(api(url, api_user), params: params) }

    before do
      stub_gitlab_api_client_to_support_gitlab_api(supported: true)
    end

    shared_examples 'updates tag rule' do
      it 'updates the tag protection rule', :aggregate_failures do
        patch_tag_rule

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to include(
          'id' => tag_rule_to_update.id,
          'tag_name_pattern' => 'updated-*',
          'minimum_access_level_for_push' => 'owner',
          'minimum_access_level_for_delete' => 'admin'
        )

        expect(tag_rule_to_update.reload.tag_name_pattern).to eq('updated-*')
      end
    end

    shared_examples 'denies update' do |status|
      it "returns #{status} and does not update rule" do
        original_pattern = tag_rule_to_update.tag_name_pattern

        patch_tag_rule

        expect(response).to have_gitlab_http_status(status)
        expect(tag_rule_to_update.reload.tag_name_pattern).to eq(original_pattern)
      end
    end

    it_behaves_like 'rejecting project protection rules request when not enough permissions'

    context 'for maintainer' do
      let(:api_user) { maintainer }

      it_behaves_like 'updates tag rule'

      context 'with partial update (single field)' do
        let(:params) { { tag_name_pattern: 'partial-update-*' } }

        it 'updates only the specified field', :aggregate_failures do
          patch_tag_rule

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to include(
            'tag_name_pattern' => 'partial-update-*',
            'minimum_access_level_for_push' => 'maintainer', # unchanged
            'minimum_access_level_for_delete' => 'maintainer' # unchanged
          )
        end
      end

      context 'when tag_name_pattern is invalid' do
        let(:params) { { tag_name_pattern: 'invalid[' } }

        it_behaves_like 'denies update', :unprocessable_entity
      end

      context 'when minimum_access_level_for_push has invalid value' do
        let(:params) { { minimum_access_level_for_push: 'invalid' } }

        it_behaves_like 'denies update', :bad_request
      end

      context 'when tag_name_pattern conflicts with existing rule' do
        let_it_be(:other_rule) do
          create(:container_registry_protection_tag_rule,
            project: project,
            tag_name_pattern: 'conflict-*')
        end

        let(:params) { { tag_name_pattern: 'conflict-*' } }

        it_behaves_like 'denies update', :unprocessable_entity

        it 'returns uniqueness error' do
          patch_tag_rule

          expect(json_response['message']['error']).to be_an(Array)
          expect(json_response['message']['error'].first).to include('has already been taken')
        end
      end

      context 'when tag_name_pattern is too long' do
        let(:params) { { tag_name_pattern: 'a' * 101 } }

        it_behaves_like 'denies update', :unprocessable_entity
      end

      it_behaves_like 'rejecting protection rules request when handling rule ids'
      it_behaves_like 'rejecting protection rules request when invalid project'
    end

    context 'with invalid token' do
      subject(:patch_tag_rule) { patch(api(url), headers: headers_with_invalid_token, params: params) }

      it_behaves_like 'returning response status', :unauthorized
    end
  end

  describe 'DELETE /projects/:id/registry/protection/tag/rules/:tag_rule_id' do
    let(:protection_rule) { tag_rule }
    let(:protection_rule_id) { protection_rule.id }
    let(:path) { "registry/protection/tag/rules/#{protection_rule_id}" }
    let(:url) { "/projects/#{project.id}/#{path}" }
    let(:headers) { {} }

    subject(:delete_tag_rule) { delete(api(url, api_user), headers: headers) }

    before do
      stub_gitlab_api_client_to_support_gitlab_api(supported: true)
    end

    it_behaves_like 'rejecting project protection rules request when not enough permissions'

    context 'for maintainer' do
      let(:api_user) { maintainer }

      it 'deletes the tag protection rule', :aggregate_failures do
        expect { delete_tag_rule }.to change { ContainerRegistry::Protection::TagRule.count }.by(-1)

        expect(response).to have_gitlab_http_status(:no_content)
        expect(response.body).to be_empty

        expect { tag_rule.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it_behaves_like 'rejecting protection rules request when handling rule ids'
      it_behaves_like 'rejecting protection rules request when invalid project'

      context 'when the GitLab API is not supported' do
        before do
          stub_gitlab_api_client_to_support_gitlab_api(supported: false)
        end

        it 'returns bad request with error message' do
          expect { delete_tag_rule }.not_to change { ContainerRegistry::Protection::TagRule.count }

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response).to eq({ 'message' => { 'error' => 'GitLab container registry API not supported' } })
        end
      end

      context 'with If-Unmodified-Since header' do
        context 'when rule has not been modified since' do
          let(:headers) { { 'If-Unmodified-Since' => 1.day.from_now.httpdate } }

          it 'deletes the rule', :aggregate_failures do
            delete_tag_rule

            expect(response).to have_gitlab_http_status(:no_content)
            expect { tag_rule.reload }.to raise_error(ActiveRecord::RecordNotFound)
          end
        end

        context 'when rule has been modified since' do
          let(:headers) { { 'If-Unmodified-Since' => 1.day.ago.httpdate } }

          it 'returns precondition failed' do
            delete_tag_rule

            expect(response).to have_gitlab_http_status(:precondition_failed)
            expect(tag_rule.reload).to be_present
          end
        end
      end
    end

    context 'for admin' do
      subject(:delete_tag_rule) { delete(api(url, admin, admin_mode: true)) }

      it 'deletes the tag protection rule' do
        expect { delete_tag_rule }.to change { ContainerRegistry::Protection::TagRule.count }.by(-1)

        expect(response).to have_gitlab_http_status(:no_content)
      end
    end

    context 'with invalid token' do
      subject(:delete_tag_rule) { delete(api(url), headers: { 'PRIVATE-TOKEN' => invalid_token }) }

      it_behaves_like 'returning response status', :unauthorized
    end
  end
end
