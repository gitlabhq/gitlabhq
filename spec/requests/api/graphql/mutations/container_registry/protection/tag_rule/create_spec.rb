# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Creating the container registry tag protection rule', :aggregate_failures, feature_category: :container_registry do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user, maintainer_of: project) }

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

  subject(:post_graphql_mutation_create) do
    post_graphql_mutation(mutation, current_user: user)
  end

  shared_examples 'a successful response' do
    it 'returns the created tag protection rule' do
      post_graphql_mutation_create

      expect(mutation_response).to include(
        'errors' => be_blank,
        'containerProtectionTagRule' => {
          'id' => be_present,
          'tagNamePattern' => input[:tag_name_pattern]
        }
      )
    end

    it 'creates container registry protection rule in the database' do
      expect { post_graphql_mutation_create }.to change { ::ContainerRegistry::Protection::TagRule.count }.by(1)

      expect(::ContainerRegistry::Protection::TagRule.where(project: project,
        tag_name_pattern: input[:tag_name_pattern])).to exist
    end
  end

  shared_examples 'not changing the protection rule count' do
    it { expect { post_graphql_mutation_create }.not_to change { ::ContainerRegistry::Protection::TagRule.count } }
  end

  it_behaves_like 'a successful response'

  context 'with invalid input fields `minimumAccessLevelForPush` and `minimumAccessLevelForDelete`' do
    let(:input) do
      super().merge(
        minimum_access_level_for_push: 'INVALID_ACCESS_LEVEL',
        minimum_access_level_for_delete: 'INVALID_ACCESS_LEVEL'
      )
    end

    it_behaves_like 'not changing the protection rule count'

    it 'returns an error' do
      post_graphql_mutation_create

      expect_graphql_errors_to_include([/minimumAccessLevelForPush/, /minimumAccessLevelForDelete/])
    end
  end

  context 'with blank input for the field `minimumAccessLevelForPush`' do
    let(:input) { super().merge(minimum_access_level_for_push: nil) }

    it_behaves_like 'not changing the protection rule count'

    it 'returns an error' do
      post_graphql_mutation_create

      expect_graphql_errors_to_include([/invalid value for minimumAccessLevelForPush/])
    end
  end

  context 'with blank input for the field `minimumAccessLevelForDelete`' do
    let(:input) { super().merge(minimum_access_level_for_delete: nil) }

    it_behaves_like 'not changing the protection rule count'

    it 'returns an error' do
      post_graphql_mutation_create

      expect_graphql_errors_to_include([/invalid value for minimumAccessLevelForDelete/])
    end
  end

  context 'with blank input field `tagNamePattern`' do
    let(:input) { super().merge(tag_name_pattern: '') }

    it_behaves_like 'not changing the protection rule count'

    it 'returns error from endpoint implementation (not from graphql framework)' do
      post_graphql_mutation_create

      expect_graphql_errors_to_include([/tagNamePattern can't be blank/])
    end
  end

  context 'with invalid input field `tagNamePattern`' do
    let(:input) { super().merge(tag_name_pattern: "*") }

    it_behaves_like 'not changing the protection rule count'

    it 'returns error from endpoint implementation (not from graphql framework)' do
      post_graphql_mutation_create

      expect_graphql_errors_to_be_empty

      expect(mutation_response['errors']).to eq [
        "Tag name pattern not valid RE2 syntax: no argument for repetition operator: *"
      ]
    end
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

      it_behaves_like 'not changing the protection rule count'

      it 'returns without error' do
        post_graphql_mutation_create

        expect(mutation_response['errors']).to eq ['Tag name pattern has already been taken']
      end

      it 'does not create new container protection rules' do
        expect(::ContainerRegistry::Protection::TagRule.where(project: project,
          tag_name_pattern: input[:tag_name_pattern],
          minimum_access_level_for_push: Gitlab::Access::OWNER)).not_to exist
      end
    end
  end

  context 'when user does not have permission' do
    let_it_be(:developer) { create(:user, developer_of: project) }
    let_it_be(:reporter) { create(:user, reporter_of: project) }
    let_it_be(:guest) { create(:user, guest_of: project) }
    let_it_be(:anonymous) { create(:user) }

    where(:user) do
      [ref(:developer), ref(:reporter), ref(:guest), ref(:anonymous)]
    end

    with_them do
      it_behaves_like 'not changing the protection rule count'

      it 'returns an error' do
        post_graphql_mutation_create.tap do
          expect_graphql_errors_to_include(/you don't have permission to perform this action/)
        end
      end
    end
  end

  context "when feature flag ':container_registry_protected_tags' disabled" do
    before do
      stub_feature_flags(container_registry_protected_tags: false)
    end

    it_behaves_like 'not changing the protection rule count'

    it 'does not create a rule' do
      post_graphql_mutation_create.tap do
        expect(::ContainerRegistry::Protection::TagRule.where(project: project)).not_to exist
      end
    end

    it 'returns error of disabled feature flag' do
      post_graphql_mutation_create.tap do
        expect_graphql_errors_to_include(/'container_registry_protected_tags' feature flag is disabled/)
      end
    end
  end
end
