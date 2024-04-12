# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Creating the container registry protection rule', :aggregate_failures, feature_category: :container_registry do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user, maintainer_of: project) }

  let(:container_registry_protection_rule_attributes) do
    build_stubbed(:container_registry_protection_rule, project: project)
  end

  let(:kwargs) do
    {
      project_path: project.full_path,
      repository_path_pattern: container_registry_protection_rule_attributes.repository_path_pattern,
      push_protected_up_to_access_level: 'MAINTAINER',
      delete_protected_up_to_access_level: 'MAINTAINER'
    }
  end

  let(:mutation) do
    graphql_mutation(:create_container_registry_protection_rule, kwargs,
      <<~QUERY
      containerRegistryProtectionRule {
        id
        repositoryPathPattern
      }
      clientMutationId
      errors
      QUERY
    )
  end

  let(:mutation_response) { graphql_mutation_response(:create_container_registry_protection_rule) }

  subject { post_graphql_mutation(mutation, current_user: user) }

  shared_examples 'a successful response' do
    it { subject.tap { expect_graphql_errors_to_be_empty } }

    it do
      subject

      expect(mutation_response).to include(
        'errors' => be_blank,
        'containerRegistryProtectionRule' => {
          'id' => be_present,
          'repositoryPathPattern' => kwargs[:repository_path_pattern]
        }
      )
    end

    it 'creates container registry protection rule in the database' do
      expect { subject }.to change { ::ContainerRegistry::Protection::Rule.count }.by(1)

      expect(::ContainerRegistry::Protection::Rule.where(project: project,
        repository_path_pattern: kwargs[:repository_path_pattern])).to exist
    end
  end

  shared_examples 'an erroneous response' do
    it { expect { subject }.not_to change { ::ContainerRegistry::Protection::Rule.count } }
  end

  it_behaves_like 'a successful response'

  context 'with invalid input fields `pushProtectedUpToAccessLevel` and `deleteProtectedUpToAccessLevel`' do
    let(:kwargs) do
      super().merge(
        push_protected_up_to_access_level: 'UNKNOWN_ACCESS_LEVEL',
        delete_protected_up_to_access_level: 'UNKNOWN_ACCESS_LEVEL'
      )
    end

    it_behaves_like 'an erroneous response'

    it {
      subject

      expect_graphql_errors_to_include([/pushProtectedUpToAccessLevel/, /deleteProtectedUpToAccessLevel/])
    }
  end

  context 'with invalid input field `repositoryPathPattern`' do
    let(:kwargs) do
      super().merge(repository_path_pattern: '')
    end

    it_behaves_like 'an erroneous response'

    it { subject.tap { expect_graphql_errors_to_be_empty } }

    it {
      subject.tap do
        expect(mutation_response['errors']).to eq [
          "Repository path pattern can't be blank, " \
          "Repository path pattern should be a valid container repository path with optional wildcard characters., " \
          "and Repository path pattern should start with the project's full path"
        ]
      end
    }
  end

  context 'with existing containers protection rule' do
    let_it_be(:existing_container_registry_protection_rule) do
      create(:container_registry_protection_rule, project: project,
        push_protected_up_to_access_level: Gitlab::Access::DEVELOPER)
    end

    context 'when container name pattern is slightly different' do
      let(:kwargs) do
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
      let(:kwargs) do
        super().merge(repository_path_pattern: existing_container_registry_protection_rule.repository_path_pattern,
          push_protected_up_to_access_level: 'MAINTAINER')
      end

      it_behaves_like 'an erroneous response'

      it { subject.tap { expect_graphql_errors_to_be_empty } }

      it 'returns without error' do
        subject

        expect(mutation_response['errors']).to eq ['Repository path pattern has already been taken']
      end

      it 'does not create new container protection rules' do
        expect(::ContainerRegistry::Protection::Rule.where(project: project,
          repository_path_pattern: kwargs[:repository_path_pattern],
          push_protected_up_to_access_level: Gitlab::Access::MAINTAINER)).not_to exist
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

  context "when feature flag ':container_registry_protected_containers' disabled" do
    before do
      stub_feature_flags(container_registry_protected_containers: false)
    end

    it_behaves_like 'an erroneous response'

    it { subject.tap { expect(::ContainerRegistry::Protection::Rule.where(project: project)).not_to exist } }

    it 'returns error of disabled feature flag' do
      subject.tap do
        expect_graphql_errors_to_include(/'container_registry_protected_containers' feature flag is disabled/)
      end
    end
  end
end
