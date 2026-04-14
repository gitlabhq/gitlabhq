# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Updating a terraform state protection rule',
  :aggregate_failures, feature_category: :infrastructure_as_code do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be_with_reload(:protection_rule) do
    create(:terraform_state_protection_rule, project: project,
      state_name: 'production',
      minimum_access_level_for_write: :maintainer,
      allowed_from: :anywhere)
  end

  let_it_be(:current_user) { create(:user, maintainer_of: project) }

  let(:input) do
    {
      id: protection_rule.to_global_id,
      state_name: 'staging',
      minimum_access_level_for_write: 'OWNER',
      allowed_from: 'CI_ONLY'
    }
  end

  let(:mutation) do
    graphql_mutation(:update_terraform_state_protection_rule, input,
      <<~QUERY
        terraformStateProtectionRule {
          stateName
          minimumAccessLevelForWrite
          allowedFrom
        }
        errors
      QUERY
    )
  end

  let(:mutation_response) { graphql_mutation_response(:update_terraform_state_protection_rule) }

  subject(:perform_request) { post_graphql_mutation(mutation, current_user: current_user) }

  shared_examples 'a successful response' do
    it 'returns without error' do
      perform_request

      expect_graphql_errors_to_be_empty
    end

    it 'returns the updated protection rule' do
      perform_request

      expect(mutation_response['terraformStateProtectionRule']).to include(
        'stateName' => expected_attributes[:state_name],
        'minimumAccessLevelForWrite' => expected_attributes[:minimum_access_level_for_write],
        'allowedFrom' => expected_attributes[:allowed_from]
      )
    end

    it 'does not change the count' do
      expect { perform_request }.not_to change { Terraform::StateProtectionRule.count }
    end
  end

  shared_examples 'an erroneous response' do
    it { perform_request.tap { expect(mutation_response).to be_blank } }
    it { expect { perform_request }.not_to change { protection_rule.reload.updated_at } }
  end

  it_behaves_like 'a successful response' do
    let(:expected_attributes) { input }
  end

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

  context 'with invalid state_name (blank)' do
    let(:input) { super().merge(state_name: '') }

    it_behaves_like 'an erroneous response'

    it 'returns a GraphQL error' do
      perform_request

      expect_graphql_errors_to_include(/stateName can't be blank/)
    end
  end

  context 'with duplicate state_name' do
    before do
      create(:terraform_state_protection_rule, project: project, state_name: 'staging')
    end

    let(:input) { super().merge(state_name: 'staging') }

    it 'returns an error in mutation response' do
      perform_request

      expect_graphql_errors_to_be_empty
      expect(mutation_response['errors']).to include(/State name has already been taken/)
    end
  end

  context 'when current_user does not have permission' do
    let_it_be(:developer) { create(:user, developer_of: project) }
    let_it_be(:guest) { create(:user, guest_of: project) }
    let_it_be(:anonymous) { create(:user) }

    where(:current_user) do
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
end
