# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Deleting a terraform state protection rule',
  :aggregate_failures, feature_category: :infrastructure_as_code do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be_with_refind(:protection_rule) do
    create(:terraform_state_protection_rule, project: project, state_name: 'production')
  end

  let_it_be(:current_user) { create(:user, maintainer_of: project) }

  let(:input) { { id: protection_rule.to_global_id } }

  let(:mutation) do
    graphql_mutation(:delete_terraform_state_protection_rule, input,
      <<~QUERY
        terraformStateProtectionRule {
          id
          stateName
        }
        errors
      QUERY
    )
  end

  let(:mutation_response) { graphql_mutation_response(:delete_terraform_state_protection_rule) }

  subject(:perform_request) { post_graphql_mutation(mutation, current_user: current_user) }

  shared_examples 'an erroneous response' do
    it { expect { perform_request }.not_to change { Terraform::StateProtectionRule.count } }
  end

  it_behaves_like 'a working GraphQL mutation'

  it 'responds with deleted protection rule' do
    perform_request

    expect(mutation_response).to include(
      'errors' => be_blank,
      'terraformStateProtectionRule' => {
        'id' => protection_rule.to_global_id.to_s,
        'stateName' => protection_rule.state_name
      }
    )
  end

  it 'deletes the rule' do
    expect { perform_request }.to change { Terraform::StateProtectionRule.count }.by(-1)
  end

  context 'when feature flag is disabled' do
    before do
      stub_feature_flags(protected_terraform_states: false)
    end

    it_behaves_like 'an erroneous response'

    it 'does not delete the rule and returns a resource not available error' do
      perform_request

      expect(protection_rule.reload).to be_present
      expect_graphql_errors_to_include(/protected_terraform_states/)
    end
  end

  context 'with protection rule belonging to other project' do
    let_it_be(:protection_rule) do
      create(:terraform_state_protection_rule, state_name: 'other-project-state')
    end

    it_behaves_like 'an erroneous response'

    it 'returns a permission error' do
      perform_request

      expect_graphql_errors_to_include(/you don't have permission to perform this action/)
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

  describe 'granular PAT authorization' do
    it_behaves_like 'authorizing granular token permissions for GraphQL',
      :delete_terraform_state_protection_rule do
      let(:user) { current_user }
      let(:boundary_object) { project }
      let(:mutation) { graphql_mutation(:delete_terraform_state_protection_rule, input, 'errors') }
      let(:request) { post_graphql_mutation(mutation, token: { personal_access_token: pat }) }
    end
  end
end
