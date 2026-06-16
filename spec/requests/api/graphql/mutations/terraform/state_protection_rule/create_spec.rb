# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Creating a terraform state protection rule',
  :aggregate_failures, feature_category: :infrastructure_as_code do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user, maintainer_of: project) }

  let(:kwargs) do
    {
      project_path: project.full_path,
      state_name: 'production',
      minimum_access_level_for_write: 'MAINTAINER',
      allowed_from: 'CI_ONLY'
    }
  end

  let(:mutation) do
    graphql_mutation(:create_terraform_state_protection_rule, kwargs,
      <<~QUERY
        terraformStateProtectionRule {
          id
          stateName
          minimumAccessLevelForWrite
          allowedFrom
        }
        errors
      QUERY
    )
  end

  let(:mutation_response) { graphql_mutation_response(:create_terraform_state_protection_rule) }

  subject(:perform_request) { post_graphql_mutation(mutation, current_user: user) }

  shared_examples 'a successful response' do
    it 'returns without error' do
      perform_request

      expect_graphql_errors_to_be_empty
      expect(mutation_response['errors']).to be_empty
    end

    it 'returns the created protection rule' do
      perform_request

      expect(mutation_response['terraformStateProtectionRule']).to include(
        'id' => be_present,
        'stateName' => kwargs[:state_name],
        'minimumAccessLevelForWrite' => kwargs[:minimum_access_level_for_write],
        'allowedFrom' => kwargs[:allowed_from]
      )
    end

    it 'creates one protection rule' do
      expect { perform_request }.to change { Terraform::StateProtectionRule.count }.by(1)
    end
  end

  shared_examples 'an erroneous response' do
    it 'does not create a protection rule' do
      expect { perform_request }.not_to change { Terraform::StateProtectionRule.count }
    end
  end

  it_behaves_like 'a successful response'

  context 'when feature flag is disabled' do
    before do
      stub_feature_flags(protected_terraform_states: false)
    end

    it_behaves_like 'an erroneous response'

    it 'returns a resource not available error' do
      perform_request

      expect_graphql_errors_to_include(/protected_terraform_states/)
    end
  end

  context 'without allowed_from (defaults to ANYWHERE)' do
    let(:kwargs) { super().except(:allowed_from) }

    it 'creates the rule with default allowed_from' do
      perform_request

      expect(mutation_response['terraformStateProtectionRule']).to include(
        'allowedFrom' => 'ANYWHERE'
      )
    end
  end

  context 'with invalid state_name (blank)' do
    let(:kwargs) { super().merge(state_name: '') }

    it_behaves_like 'an erroneous response'

    it 'returns an error' do
      perform_request

      expect(mutation_response['errors']).to include(/State name can't be blank/)
    end
  end

  context 'with existing protection rule for same state_name' do
    before do
      create(:terraform_state_protection_rule, project: project, state_name: 'production')
    end

    it_behaves_like 'an erroneous response'

    it 'returns an error' do
      perform_request

      expect(mutation_response['errors']).to include(/State name has already been taken/)
    end
  end

  context 'when user does not have permission' do
    let_it_be(:developer) { create(:user, developer_of: project) }
    let_it_be(:guest) { create(:user, guest_of: project) }
    let_it_be(:anonymous) { create(:user) }

    where(:user) do
      [ref(:developer), ref(:guest), ref(:anonymous)]
    end

    with_them do
      it_behaves_like 'an erroneous response'

      it 'returns a permission error' do
        perform_request

        expect_graphql_errors_to_include(/you don't have permission to perform this action/)
      end
    end
  end

  describe 'granular PAT authorization' do
    it_behaves_like 'authorizing granular token permissions for GraphQL',
      :create_terraform_state_protection_rule do
      let(:boundary_object) { project }
      let(:mutation) { graphql_mutation(:create_terraform_state_protection_rule, kwargs, 'errors') }
      let(:request) { post_graphql_mutation(mutation, token: { personal_access_token: pat }) }
    end
  end
end
