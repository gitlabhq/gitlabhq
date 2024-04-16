# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Updating the container registry protection rule', :aggregate_failures, feature_category: :container_registry do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be_with_reload(:container_registry_protection_rule) do
    create(:container_registry_protection_rule, project: project, push_protected_up_to_access_level: :developer)
  end

  let_it_be(:current_user) { create(:user, maintainer_of: project) }

  let(:container_registry_protection_rule_attributes) do
    build_stubbed(:container_registry_protection_rule, project: project)
  end

  let(:mutation) do
    graphql_mutation(:update_container_registry_protection_rule, input,
      <<~QUERY
      containerRegistryProtectionRule {
        repositoryPathPattern
        deleteProtectedUpToAccessLevel
        pushProtectedUpToAccessLevel
      }
      clientMutationId
      errors
      QUERY
    )
  end

  let(:input) do
    {
      id: container_registry_protection_rule.to_global_id,
      repository_path_pattern: "#{container_registry_protection_rule.repository_path_pattern}-updated",
      delete_protected_up_to_access_level: 'OWNER',
      push_protected_up_to_access_level: 'MAINTAINER'
    }
  end

  let(:mutation_response) { graphql_mutation_response(:update_container_registry_protection_rule) }

  subject { post_graphql_mutation(mutation, current_user: current_user) }

  shared_examples 'a successful response' do
    it { subject.tap { expect_graphql_errors_to_be_empty } }

    it 'returns the updated container registry protection rule' do
      subject

      expect(mutation_response).to include(
        'containerRegistryProtectionRule' => {
          'repositoryPathPattern' => input[:repository_path_pattern],
          'deleteProtectedUpToAccessLevel' => input[:delete_protected_up_to_access_level],
          'pushProtectedUpToAccessLevel' => input[:push_protected_up_to_access_level]
        }
      )
    end

    it do
      subject.tap do
        expect(container_registry_protection_rule.reload).to have_attributes(
          repository_path_pattern: input[:repository_path_pattern],
          push_protected_up_to_access_level: input[:push_protected_up_to_access_level].downcase
        )
      end
    end
  end

  shared_examples 'an erroneous response' do
    it { subject.tap { expect(mutation_response).to be_blank } }
    it { expect { subject }.not_to change { container_registry_protection_rule.reload.updated_at } }
  end

  it_behaves_like 'a successful response'

  context 'with other existing container registry protection rule with same repository_path_pattern' do
    let_it_be_with_reload(:other_existing_container_registry_protection_rule) do
      create(:container_registry_protection_rule, project: project,
        repository_path_pattern: "#{container_registry_protection_rule.repository_path_pattern}-other")
    end

    let(:input) do
      super().merge(repository_path_pattern: other_existing_container_registry_protection_rule.repository_path_pattern)
    end

    it { is_expected.tap { expect_graphql_errors_to_be_empty } }

    it 'returns a blank container registry protection rule' do
      is_expected.tap { expect(mutation_response['containerRegistryProtectionRule']).to be_blank }
    end

    it 'includes error message in response' do
      is_expected.tap { expect(mutation_response['errors']).to eq ['Repository path pattern has already been taken'] }
    end
  end

  context 'with invalid input param `pushProtectedUpToAccessLevel`' do
    let(:input) { super().merge(push_protected_up_to_access_level: nil) }

    it_behaves_like 'an erroneous response'

    it { is_expected.tap { expect_graphql_errors_to_include(/pushProtectedUpToAccessLevel can't be blank/) } }
  end

  context 'with invalid input param `repositoryPathPattern`' do
    let(:input) { super().merge(repository_path_pattern: '') }

    it_behaves_like 'an erroneous response'

    it { is_expected.tap { expect_graphql_errors_to_include(/repositoryPathPattern can't be blank/) } }
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
      it { is_expected.tap { expect_graphql_errors_to_include(/you don't have permission to perform this action/) } }
    end
  end

  context "when feature flag ':container_registry_protected_containers' disabled" do
    before do
      stub_feature_flags(container_registry_protected_containers: false)
    end

    it_behaves_like 'an erroneous response'

    it 'returns error of disabled feature flag' do
      is_expected.tap do
        expect_graphql_errors_to_include(/'container_registry_protected_containers' feature flag is disabled/)
      end
    end
  end
end
