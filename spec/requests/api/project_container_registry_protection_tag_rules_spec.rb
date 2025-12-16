# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ProjectContainerRegistryProtectionTagRules, :aggregate_failures,
  feature_category: :container_registry do
  let_it_be(:project) { create(:project, :private) }
  let_it_be(:other_project) { create(:project, :private) }
  let_it_be(:tag_rule) do
    create(:container_registry_protection_tag_rule, project: project, tag_name_pattern: 'v*')
  end

  let_it_be(:maintainer) { create(:user, maintainer_of: [project, other_project]) }
  let_it_be(:admin) { create(:admin) }
  let_it_be(:api_user) { create(:user) }

  let_it_be(:path) { 'registry/protection/tag/rules' }
  let_it_be(:url) { "/projects/#{project.id}/#{path}" }
  let_it_be(:invalid_token) { 'invalid-token123' }

  describe 'GET /projects/:id/registry/protection/tag/rules' do
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
      subject(:get_tag_rules) { get(api(url), headers: { 'PRIVATE-TOKEN' => invalid_token }) }

      it_behaves_like 'returning response status', :unauthorized
    end
  end
end
