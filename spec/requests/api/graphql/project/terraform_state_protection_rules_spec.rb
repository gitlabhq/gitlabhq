# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting the terraform state protection rules linked to a project',
  :aggregate_failures, feature_category: :infrastructure_as_code do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { project.owner }

  let(:query) do
    graphql_query_for(
      :project,
      { full_path: project.full_path },
      query_nodes(:terraformStateProtectionRules, of: 'TerraformStateProtectionRule')
    )
  end

  subject(:perform_request) { post_graphql(query, current_user: user) }

  context 'with authorized user (maintainer)' do
    context 'with terraform state protection rule' do
      let_it_be(:protection_rule) do
        create(:terraform_state_protection_rule,
          project: project,
          state_name: 'production',
          minimum_access_level_for_write: :maintainer,
          allowed_from: :ci_only)
      end

      before do
        perform_request
      end

      it_behaves_like 'a working graphql query'

      it 'returns one TerraformStateProtectionRule' do
        expect(graphql_data_at(:project, :terraformStateProtectionRules, :nodes).count).to eq 1
      end

      it 'returns all protection rule fields' do
        expect(graphql_data_at(:project, :terraformStateProtectionRules, :nodes)).to include(
          hash_including(
            'stateName' => 'production',
            'minimumAccessLevelForWrite' => 'MAINTAINER',
            'allowedFrom' => 'CI_ONLY'
          )
        )
      end

      it 'avoids N+1 queries' do
        control = ActiveRecord::QueryRecorder.new { post_graphql(query, current_user: user) }

        create(:terraform_state_protection_rule, project: project, state_name: 'staging')

        expect { post_graphql(query, current_user: user) }.not_to exceed_query_limit(control)
      end
    end

    context 'without terraform state protection rules' do
      before do
        perform_request
      end

      it_behaves_like 'a working graphql query'

      it 'returns no rules' do
        expect(graphql_data_at(:project, :terraformStateProtectionRules, :nodes)).to eq []
      end
    end
  end

  context 'when feature flag is disabled' do
    let_it_be(:protection_rule) do
      create(:terraform_state_protection_rule, project: project, state_name: 'production')
    end

    before do
      stub_feature_flags(protected_terraform_states: false)
      perform_request
    end

    it_behaves_like 'a working graphql query'

    it 'returns no protection rules' do
      expect(graphql_data_at(:project, :terraformStateProtectionRules, :nodes)).to eq []
    end
  end

  context 'with developer user' do
    let_it_be(:user) { create(:user, developer_of: project) }
    let_it_be(:protection_rule) do
      create(:terraform_state_protection_rule, project: project, state_name: 'production')
    end

    before do
      perform_request
    end

    it_behaves_like 'a working graphql query'

    it 'returns protection rules' do
      expect(graphql_data_at(:project, :terraformStateProtectionRules, :nodes).count).to eq 1
    end
  end

  context 'with unauthorized user (guest)' do
    let_it_be(:user) { create(:user, guest_of: project) }

    before do
      perform_request
    end

    it_behaves_like 'a working graphql query'

    it 'returns no protection rules' do
      expect(graphql_data_at(:project, :terraformStateProtectionRules, :nodes)).to eq []
    end
  end
end
