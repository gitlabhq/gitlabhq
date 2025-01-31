# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Creating the container registry tag protection rule', :aggregate_failures, feature_category: :container_registry do
  include ContainerRegistryHelpers
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:current_user) { create(:user, maintainer_of: project) }

  let(:tag_rule_attributes) do
    build_stubbed(:container_registry_protection_tag_rule, project: project)
  end

  let(:input) do
    {
      project_path: project.full_path,
      tag_name_pattern: tag_rule_attributes.tag_name_pattern,
      minimum_access_level_for_push: 'MAINTAINER',
      minimum_access_level_for_delete: 'MAINTAINER'
    }
  end

  let(:mutation) do
    graphql_mutation(:create_container_protection_tag_rule, input,
      <<~QUERY
      containerProtectionTagRule {
        id
        tagNamePattern
      }
      clientMutationId
      errors
      QUERY
    )
  end

  let(:mutation_response) { graphql_mutation_response(:create_container_protection_tag_rule) }

  before do
    stub_gitlab_api_client_to_support_gitlab_api(supported: true)
  end

  subject(:post_graphql_mutation_request) do
    post_graphql_mutation(mutation, current_user: current_user)
  end

  shared_examples 'a successful response' do
    it 'returns the created tag protection rule' do
      post_graphql_mutation_request.tap do
        expect(mutation_response).to include(
          'errors' => be_blank,
          'containerProtectionTagRule' => {
            'id' => be_present,
            'tagNamePattern' => input[:tag_name_pattern]
          }
        )
      end
    end

    it 'creates container registry protection rule in the database' do
      expect { post_graphql_mutation_request }.to change { ::ContainerRegistry::Protection::TagRule.count }.by(1)

      expect(::ContainerRegistry::Protection::TagRule.where(project: project,
        tag_name_pattern: input[:tag_name_pattern])).to exist
    end
  end

  shared_examples 'not persisting changes' do
    it { expect { post_graphql_mutation_request }.not_to change { ::ContainerRegistry::Protection::TagRule.count } }
  end

  it_behaves_like 'a successful response'

  context 'with invalid input fields `minimumAccessLevelForPush` and `minimumAccessLevelForDelete`' do
    let(:input) do
      super().merge(
        minimum_access_level_for_push: 'INVALID_ACCESS_LEVEL',
        minimum_access_level_for_delete: 'INVALID_ACCESS_LEVEL'
      )
    end

    it_behaves_like 'returning a GraphQL error', [/minimumAccessLevelForPush/, /minimumAccessLevelForDelete/]
  end

  context 'with blank input for the field `minimumAccessLevelForPush`' do
    let(:input) { super().merge(minimum_access_level_for_push: nil) }

    it_behaves_like 'returning a mutation error', 'Access levels should either both be present or both be nil'
  end

  context 'with blank input for the field `minimumAccessLevelForDelete`' do
    let(:input) { super().merge(minimum_access_level_for_delete: nil) }

    it_behaves_like 'returning a mutation error', 'Access levels should either both be present or both be nil'
  end

  context 'with both access levels blank' do
    let(:input) { super().merge(minimum_access_level_for_delete: nil, minimum_access_level_for_push: nil) }

    it_behaves_like 'a successful response'
  end

  context 'with blank input field `tagNamePattern`' do
    let(:input) { super().merge(tag_name_pattern: '') }

    it_behaves_like 'returning a GraphQL error', /tagNamePattern can't be blank/
  end

  context 'with invalid input field `tagNamePattern`' do
    let(:input) { super().merge(tag_name_pattern: '*') }

    it_behaves_like 'returning a mutation error',
      'Tag name pattern not valid RE2 syntax: no argument for repetition operator: *'
  end

  context 'with existing containers protection rule' do
    let_it_be(:existing_tag_protection_rule) do
      create(:container_registry_protection_tag_rule, project: project,
        minimum_access_level_for_push: Gitlab::Access::MAINTAINER)
    end

    context 'when field `tag_name_pattern` is taken' do
      let(:input) do
        super().merge(tag_name_pattern: existing_tag_protection_rule.tag_name_pattern,
          minimum_access_level_for_push: 'OWNER')
      end

      it_behaves_like 'returning a mutation error', 'Tag name pattern has already been taken'
    end
  end

  include_examples 'when user does not have permission'
  include_examples 'when feature flag container_registry_protected_tags is disabled'
  include_examples 'when the GitLab API is not supported'
end
