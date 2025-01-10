# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Deleting a container registry protection rule', :aggregate_failures, feature_category: :container_registry do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be_with_refind(:container_protection_rule) do
    create(:container_registry_protection_rule, project: project)
  end

  let_it_be(:current_user) { create(:user, maintainer_of: project) }

  let(:mutation) { graphql_mutation(:delete_container_protection_repository_rule, input) }
  let(:mutation_response) { graphql_mutation_response(:delete_container_protection_repository_rule) }
  let(:input) { { id: container_protection_rule.to_global_id } }

  subject(:post_graphql_mutation_delete_container_registry_protection_rule) do
    post_graphql_mutation(mutation, current_user: current_user)
  end

  shared_examples 'an erroneous response' do
    it { post_graphql_mutation_delete_container_registry_protection_rule.tap { expect(mutation_response).to be_blank } }

    it do
      expect { post_graphql_mutation_delete_container_registry_protection_rule }
        .not_to change { ::ContainerRegistry::Protection::Rule.count }
    end
  end

  it_behaves_like 'a working GraphQL mutation'

  it 'responds with deleted container registry protection rule' do
    expect { post_graphql_mutation_delete_container_registry_protection_rule }
      .to change { ::ContainerRegistry::Protection::Rule.count }.from(1).to(0)

    expect_graphql_errors_to_be_empty

    expect(mutation_response).to include(
      'errors' => be_blank,
      'containerProtectionRepositoryRule' => {
        'id' => container_protection_rule.to_global_id.to_s,
        'repositoryPathPattern' => container_protection_rule.repository_path_pattern,
        'minimumAccessLevelForDelete' => container_protection_rule.minimum_access_level_for_delete.upcase,
        'minimumAccessLevelForPush' => container_protection_rule.minimum_access_level_for_push.upcase
      }
    )
  end

  context 'with existing container registry protection rule belonging to other project' do
    let_it_be(:container_protection_rule) { create(:container_registry_protection_rule) }

    it_behaves_like 'an erroneous response'

    it { is_expected.tap { expect_graphql_errors_to_include(/you don't have permission to perform this action/) } }
  end

  context 'with deleted container registry protection rule' do
    let!(:container_protection_rule) do
      create(:container_registry_protection_rule, project: project,
        repository_path_pattern: "#{project.full_path}/image-deleted").destroy!
    end

    it_behaves_like 'an erroneous response'

    it { is_expected.tap { expect_graphql_errors_to_include(/you don't have permission to perform this action/) } }
  end

  context 'when current_user does not have permission' do
    let_it_be(:developer) { create(:user, developer_of: project) }
    let_it_be(:reporter) { create(:user, reporter_of: project) }
    let_it_be(:guest) { create(:user, guest_of: project) }
    let_it_be(:anonymous) { create(:user) }

    where(:current_user) do
      [ref(:developer), ref(:reporter), ref(:guest), ref(:anonymous)]
    end

    with_them do
      it_behaves_like 'an erroneous response'

      it { is_expected.tap { expect_graphql_errors_to_include(/you don't have permission to perform this action/) } }
    end
  end
end
