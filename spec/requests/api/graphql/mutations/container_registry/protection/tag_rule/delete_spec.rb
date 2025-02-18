# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Deleting a container registry tag protection rule', :aggregate_failures, feature_category: :container_registry do
  include ContainerRegistryHelpers
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be_with_refind(:container_protection_rule) do
    create(:container_registry_protection_tag_rule, project: project)
  end

  let_it_be(:current_user) { create(:user, maintainer_of: project) }

  let(:mutation) { graphql_mutation(:delete_container_protection_tag_rule, input) }
  let(:mutation_response) { graphql_mutation_response(:delete_container_protection_tag_rule) }
  let(:input) { { id: container_protection_rule.to_global_id } }

  before do
    stub_gitlab_api_client_to_support_gitlab_api(supported: true)
  end

  subject(:post_graphql_mutation_request) do
    post_graphql_mutation(mutation, current_user: current_user)
  end

  shared_examples 'not persisting changes' do
    it 'does not delete the protection rule' do
      expect { post_graphql_mutation_request }
        .not_to change { ::ContainerRegistry::Protection::TagRule.count }
    end
  end

  it_behaves_like 'a working GraphQL mutation'

  it 'responds with deleted container registry tag protection rule' do
    expect { post_graphql_mutation_request }
      .to change { ::ContainerRegistry::Protection::TagRule.count }.from(1).to(0)

    expect(mutation_response).to include(
      'errors' => be_blank,
      'containerProtectionTagRule' => {
        'id' => container_protection_rule.to_global_id.to_s,
        'tagNamePattern' => container_protection_rule.tag_name_pattern,
        'minimumAccessLevelForDelete' => container_protection_rule.minimum_access_level_for_delete.upcase,
        'minimumAccessLevelForPush' => container_protection_rule.minimum_access_level_for_push.upcase
      }
    )
  end

  context 'with existing container registry tag protection rule belonging to other project' do
    let_it_be(:container_protection_rule) { create(:container_registry_protection_tag_rule) }

    it_behaves_like 'returning a GraphQL error', /you don't have permission to perform this action/
  end

  context 'with deleted container registry tag protection rule' do
    let!(:container_protection_rule) do
      create(:container_registry_protection_tag_rule, project: project, tag_name_pattern: 'v1*').destroy!
    end

    it_behaves_like 'returning a GraphQL error', /you don't have permission to perform this action/
  end

  include_examples 'when user does not have permission'
  include_examples 'when feature flag container_registry_protected_tags is disabled'
  include_examples 'when the GitLab API is not supported'
end
