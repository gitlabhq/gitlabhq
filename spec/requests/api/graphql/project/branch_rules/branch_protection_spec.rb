# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting branch protection for a branch rule', feature_category: :source_code_management do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:branch_rule) { create(:protected_branch) }
  let_it_be(:project) { branch_rule.project }

  let(:branch_protection_data) do
    graphql_data_at('project', 'branchRules', 'nodes', 1, 'branchProtection')
  end

  let(:variables) { { path: project.full_path } }

  let(:fields) { all_graphql_fields_for('BranchProtection') }

  let(:query) do
    <<~GQL
    query($path: ID!) {
      project(fullPath: $path) {
        branchRules(first: 2) {
          nodes {
            branchProtection {
              #{fields}
            }
          }
        }
      }
    }
    GQL
  end

  shared_examples_for 'branch protection graphql query' do
    context 'when the user does not have read_protected_branch abilities' do
      before do
        project.add_guest(current_user)
        post_graphql(query, current_user: current_user, variables: variables)
      end

      it_behaves_like 'a working graphql query'

      it { expect(branch_protection_data).not_to be_present }
    end

    context 'when the user does have read_protected_branch abilities' do
      before do
        project.add_maintainer(current_user)
        post_graphql(query, current_user: current_user, variables: variables)
      end

      it_behaves_like 'a working graphql query'

      it 'includes allow_force_push' do
        expect(branch_protection_data['allowForcePush']).to be_in([true, false])
        expect(branch_protection_data['allowForcePush']).to eq(branch_rule.allow_force_push)
      end
    end
  end

  it_behaves_like 'branch protection graphql query'

  context 'when the branch_rule_squash_settings flag is not enabled' do
    before do
      stub_feature_flags(branch_rule_squash_settings: false)
    end

    it_behaves_like 'branch protection graphql query' do
      let(:branch_protection_data) do
        graphql_data_at('project', 'branchRules', 'nodes', 0, 'branchProtection')
      end
    end
  end
end
