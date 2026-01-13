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

  describe 'GET /projects/:id/registry/protection/tag/rules' do
    let(:path) { 'registry/protection/tag/rules' }
    let(:url) { "/projects/#{project.id}/#{path}" }

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
end
