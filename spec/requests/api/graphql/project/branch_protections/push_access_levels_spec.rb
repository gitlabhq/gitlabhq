# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting push access levels for a branch protection' do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }

  let(:push_access_level_data) { push_access_levels_data[0] }

  let(:push_access_levels_data) do
    graphql_data_at('project',
                    'branchRules',
                    'nodes',
                    0,
                    'branchProtection',
                    'pushAccessLevels',
                    'nodes')
  end

  let(:project) { protected_branch.project }

  let(:push_access_levels_count) { protected_branch.push_access_levels.size }

  let(:variables) { { path: project.full_path } }

  let(:fields) { all_graphql_fields_for('PushAccessLevel'.classify) }

  let(:query) do
    <<~GQL
    query($path: ID!) {
      project(fullPath: $path) {
        branchRules(first: 1) {
          nodes {
            branchProtection {
              pushAccessLevels {
                nodes {
                  #{fields}
                }
              }
            }
          }
        }
      }
    }
    GQL
  end

  context 'when the user does not have read_protected_branch abilities' do
    let_it_be(:protected_branch) { create(:protected_branch) }

    before do
      project.add_guest(current_user)
      post_graphql(query, current_user: current_user, variables: variables)
    end

    it_behaves_like 'a working graphql query'

    it { expect(push_access_levels_data).not_to be_present }
  end

  shared_examples 'push access request' do
    let(:push_access) { protected_branch.push_access_levels.first }

    before do
      project.add_maintainer(current_user)
      post_graphql(query, current_user: current_user, variables: variables)
    end

    it_behaves_like 'a working graphql query'

    it 'returns all push access levels' do
      expect(push_access_levels_data.size).to eq(push_access_levels_count)
    end

    it 'includes access_level' do
      expect(push_access_level_data['accessLevel'])
        .to eq(push_access.access_level)
    end

    it 'includes access_level_description' do
      expect(push_access_level_data['accessLevelDescription'])
        .to eq(push_access.humanize)
    end
  end

  context 'when the user does have read_protected_branch abilities' do
    let(:push_access) { protected_branch.push_access_levels.first }

    context 'when no one has access' do
      let_it_be(:protected_branch) { create(:protected_branch, :no_one_can_push) }

      it_behaves_like 'push access request'
    end

    context 'when developers have access' do
      let_it_be(:protected_branch) { create(:protected_branch, :developers_can_push) }

      it_behaves_like 'push access request'
    end

    context 'when maintainers have access' do
      let_it_be(:protected_branch) { create(:protected_branch, :maintainers_can_push) }

      it_behaves_like 'push access request'
    end
  end
end
