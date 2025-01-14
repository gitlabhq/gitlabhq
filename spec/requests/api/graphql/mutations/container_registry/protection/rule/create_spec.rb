# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Creating the container registry protection rule', :aggregate_failures, feature_category: :container_registry do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user, maintainer_of: project) }

  let(:container_registry_protection_rule_attributes) do
    build_stubbed(:container_registry_protection_rule, project: project)
  end

  let(:input) do
    {
      project_path: project.full_path,
      repository_path_pattern: container_registry_protection_rule_attributes.repository_path_pattern,
      minimum_access_level_for_push: 'MAINTAINER',
      minimum_access_level_for_delete: 'MAINTAINER'
    }
  end

  let(:mutation) do
    graphql_mutation(:create_container_protection_repository_rule, input,
      <<~QUERY
      containerProtectionRepositoryRule {
        id
        repositoryPathPattern
      }
      clientMutationId
      errors
      QUERY
    )
  end

  let(:mutation_response) { graphql_mutation_response(:create_container_protection_repository_rule) }

  subject(:post_graphql_mutation_create_container_registry_protection_rule) {
    post_graphql_mutation(mutation, current_user: user)
  }

  shared_examples 'a successful response' do
    it { subject.tap { expect_graphql_errors_to_be_empty } }

    it do
      subject

      expect(mutation_response).to include(
        'errors' => be_blank,
        'containerProtectionRepositoryRule' => {
          'id' => be_present,
          'repositoryPathPattern' => input[:repository_path_pattern]
        }
      )
    end

    it 'creates container registry protection rule in the database' do
      expect { subject }.to change { ::ContainerRegistry::Protection::Rule.count }.by(1)

      expect(::ContainerRegistry::Protection::Rule.where(project: project,
        repository_path_pattern: input[:repository_path_pattern])).to exist
    end
  end

  shared_examples 'an erroneous response' do
    it { expect { subject }.not_to change { ::ContainerRegistry::Protection::Rule.count } }
  end

  it_behaves_like 'a successful response'

  context 'with invalid input fields `minimumAccessLevelForPush` and `minimumAccessLevelForDelete`' do
    let(:input) do
      super().merge(
        minimum_access_level_for_push: 'INVALID_ACCESS_LEVEL',
        minimum_access_level_for_delete: 'INVALID_ACCESS_LEVEL'
      )
    end

    it_behaves_like 'an erroneous response'

    it {
      subject

      expect_graphql_errors_to_include([/minimumAccessLevelForPush/, /minimumAccessLevelForDelete/])
    }
  end

  context 'with blank input fields `minimumAccessLevelForPush` and `minimumAccessLevelForDelete`' do
    let(:input) { super().merge(minimum_access_level_for_push: nil, minimum_access_level_for_delete: nil) }

    it_behaves_like 'an erroneous response'

    it 'returns error with correct error message' do
      subject

      expect(mutation_response['errors']).to eq ['A rule must have at least a minimum access role for push or delete.']
    end
  end

  context 'with blank input field `repositoryPathPattern`' do
    let(:input) { super().merge(repository_path_pattern: '') }

    it_behaves_like 'an erroneous response'

    it 'returns error from endpoint implementation (not from graphql framework)' do
      post_graphql_mutation_create_container_registry_protection_rule

      expect_graphql_errors_to_include([/repositoryPathPattern can't be blank/])
    end
  end

  context 'with invalid input field `repositoryPathPattern`' do
    let(:input) { super().merge(repository_path_pattern: "prefix-#{project.full_path}-invalid-character-!") }

    it_behaves_like 'an erroneous response'

    it 'returns error from endpoint implementation (not from graphql framework)' do
      post_graphql_mutation_create_container_registry_protection_rule

      expect_graphql_errors_to_be_empty

      expect(mutation_response['errors']).to eq [
        "Repository path pattern should be a valid container repository path with optional wildcard characters.",
        "Repository path pattern should start with the project's full path"
      ]
    end
  end

  context 'with existing containers protection rule' do
    let_it_be(:existing_container_registry_protection_rule) do
      create(:container_registry_protection_rule, project: project,
        minimum_access_level_for_push: Gitlab::Access::MAINTAINER)
    end

    context 'when container name pattern is slightly different' do
      let(:input) do
        # The field `repository_path_pattern` is unique; this is why we change the value in a minimum way
        super().merge(
          repository_path_pattern: "#{existing_container_registry_protection_rule.repository_path_pattern}-unique"
        )
      end

      it_behaves_like 'a successful response'

      it 'adds another container registry protection rule to the database' do
        expect { subject }.to change { ::ContainerRegistry::Protection::Rule.count }.from(1).to(2)
      end
    end

    context 'when field `repository_path_pattern` is taken' do
      let(:input) do
        super().merge(repository_path_pattern: existing_container_registry_protection_rule.repository_path_pattern,
          minimum_access_level_for_push: 'OWNER')
      end

      it_behaves_like 'an erroneous response'

      it { subject.tap { expect_graphql_errors_to_be_empty } }

      it 'returns without error' do
        subject

        expect(mutation_response['errors']).to eq ['Repository path pattern has already been taken']
      end

      it 'does not create new container protection rules' do
        expect(::ContainerRegistry::Protection::Rule.where(project: project,
          repository_path_pattern: input[:repository_path_pattern],
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
      it_behaves_like 'an erroneous response'

      it { subject.tap { expect_graphql_errors_to_include(/you don't have permission to perform this action/) } }
    end
  end
end
