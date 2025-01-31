# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Updating the container registry tag protection rule', :aggregate_failures, feature_category: :container_registry do
  include ContainerRegistryHelpers
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be_with_reload(:container_protection_tag_rule) do
    create(:container_registry_protection_tag_rule, project: project)
  end

  let_it_be(:current_user) { create(:user, maintainer_of: project) }

  let(:container_protection_tag_rule_attributes) do
    build_stubbed(:container_protection_tag_rule, project: project)
  end

  let(:mutation) do
    graphql_mutation(:update_container_protection_tag_rule, input,
      <<~QUERY
      containerProtectionTagRule {
        tagNamePattern
        minimumAccessLevelForDelete
        minimumAccessLevelForPush
      }
      clientMutationId
      errors
      QUERY
    )
  end

  let(:input) do
    {
      id: container_protection_tag_rule.to_global_id,
      tag_name_pattern: 'v2*',
      minimum_access_level_for_delete: 'OWNER',
      minimum_access_level_for_push: 'MAINTAINER'
    }
  end

  let(:mutation_response) { graphql_mutation_response(:update_container_protection_tag_rule) }

  before do
    stub_gitlab_api_client_to_support_gitlab_api(supported: true)
  end

  subject(:post_graphql_mutation_request) do
    post_graphql_mutation(mutation, current_user: current_user)
  end

  shared_examples 'a successful response' do
    it 'returns the updated container registry tag protection rule' do
      post_graphql_mutation_request.tap do
        expect(mutation_response).to include(
          'errors' => be_blank,
          'containerProtectionTagRule' => {
            'tagNamePattern' => input[:tag_name_pattern],
            'minimumAccessLevelForDelete' => input[:minimum_access_level_for_delete],
            'minimumAccessLevelForPush' => input[:minimum_access_level_for_push]
          }
        )
      end
    end

    it 'updates the rule with the right attributes' do
      post_graphql_mutation_request.tap do
        expect(container_protection_tag_rule.reload).to have_attributes(
          tag_name_pattern: input[:tag_name_pattern],
          minimum_access_level_for_push: input[:minimum_access_level_for_push]&.downcase,
          minimum_access_level_for_delete: input[:minimum_access_level_for_delete]&.downcase
        )
      end
    end
  end

  shared_examples 'not persisting changes' do
    it 'does not update the tag rule' do
      expect { post_graphql_mutation_request }
        .not_to(change { container_protection_tag_rule.reload.updated_at })
    end
  end

  it_behaves_like 'a successful response'

  context 'with other existing container registry protection rule with same tag_name_pattern' do
    let_it_be_with_reload(:other_existing_container_protection_tag_rule) do
      create(:container_registry_protection_tag_rule, project: project,
        tag_name_pattern: "#{container_protection_tag_rule.tag_name_pattern}-other")
    end

    let(:input) do
      super().merge(tag_name_pattern: other_existing_container_protection_tag_rule.tag_name_pattern)
    end

    it 'returns a blank container registry tag protection rule' do
      post_graphql_mutation_request.tap do
        expect(mutation_response['containerProtectionTagRule']).to be_blank
      end
    end

    it_behaves_like 'returning a mutation error', 'Tag name pattern has already been taken'
  end

  context 'with invalid input param `minimumAccessLevelForPush`' do
    let(:input) { super().merge(minimum_access_level_for_push: 'INVALID_ACCESS_LEVEL') }

    it_behaves_like 'returning a GraphQL error', /invalid value for minimumAccessLevelForPush/
  end

  context 'with invalid input param `minimumAccessLevelForDelete`' do
    let(:input) { super().merge(minimum_access_level_for_delete: 'INVALID_ACCESS_LEVEL') }

    it_behaves_like 'returning a GraphQL error', /invalid value for minimumAccessLevelForDelete/
  end

  context 'with invalid input param `tagNamePattern`' do
    let(:input) { super().merge(tag_name_pattern: '') }

    it_behaves_like 'returning a GraphQL error', /tagNamePattern can't be blank/
  end

  context 'with blank input fields `minimumAccessLevelForPush` and `minimumAccessLevelForDelete`' do
    let(:input) { super().merge(minimum_access_level_for_push: nil, minimum_access_level_for_delete: nil) }

    it_behaves_like 'a successful response'
  end

  context 'with only `minimumAccessLevelForDelete` blank' do
    let(:input) { super().merge(minimum_access_level_for_delete: nil) }

    it_behaves_like 'returning a mutation error', 'Access levels should either both be present or both be nil'
  end

  context 'with only `minimumAccessLevelForPush` blank' do
    let(:input) { super().merge(minimum_access_level_for_push: nil) }

    it_behaves_like 'returning a mutation error', 'Access levels should either both be present or both be nil'
  end

  include_examples 'when user does not have permission'
  include_examples 'when feature flag container_registry_protected_tags is disabled'
  include_examples 'when the GitLab API is not supported'
end
