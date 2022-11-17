# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting list of branch rules for a project' do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository, :public) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:branch_name_a) { TestEnv::BRANCH_SHA.each_key.first }
  let_it_be(:branch_name_b) { 'diff-*' }
  let_it_be(:branch_rules) { [branch_rule_a, branch_rule_b] }
  let_it_be(:branch_rule_a) do
    create(:protected_branch, project: project, name: branch_name_a)
  end

  let_it_be(:branch_rule_b) do
    create(:protected_branch, project: project, name: branch_name_b)
  end

  let(:branch_rules_data) { graphql_data_at('project', 'branchRules', 'edges') }
  let(:variables) { { path: project.full_path } }
  let(:fields) { all_graphql_fields_for('BranchRule') }
  let(:query) do
    <<~GQL
    query($path: ID!, $n: Int, $cursor: String) {
      project(fullPath: $path) {
        branchRules(first: $n, after: $cursor) {
          pageInfo {
            hasNextPage
            hasPreviousPage
          }
          edges {
            cursor
            node {
              #{fields}
            }
          }
        }
      }
    }
    GQL
  end

  context 'when the user does not have read_protected_branch abilities' do
    before do
      project.add_guest(current_user)
      post_graphql(query, current_user: current_user, variables: variables)
    end

    it_behaves_like 'a working graphql query'

    it 'hides branch rules data' do
      expect(branch_rules_data).to be_empty
    end
  end

  context 'when the user does have read_protected_branch abilities' do
    before do
      project.add_maintainer(current_user)
    end

    describe 'queries' do
      before do
        # rubocop:disable RSpec/AnyInstanceOf
        allow_any_instance_of(User).to receive(:update_tracked_fields!)
        allow_any_instance_of(Users::ActivityService).to receive(:execute)
        # rubocop:enable RSpec/AnyInstanceOf
        allow_next_instance_of(Resolvers::ProjectResolver) do |resolver|
          allow(resolver).to receive(:resolve)
            .with(full_path: project.full_path)
            .and_return(project)
        end
        allow(project.repository).to receive(:branch_names).and_call_original
        allow(project.repository.gitaly_ref_client).to receive(:branch_names).and_call_original
      end

      it 'matching_branches_count avoids N+1 queries' do
        query = <<~GQL
          query($path: ID!) {
            project(fullPath: $path) {
              branchRules {
                nodes {
                  matchingBranchesCount
                }
              }
            }
          }
        GQL

        control = ActiveRecord::QueryRecorder.new do
          post_graphql(query, current_user: current_user, variables: variables)
        end

        # Verify the response includes the field
        expect_n_matching_branches_count_fields(2)

        create(:protected_branch, project: project)
        create(:protected_branch, name: '*', project: project)

        expect do
          post_graphql(query, current_user: current_user, variables: variables)
        end.not_to exceed_all_query_limit(control)

        expect(project.repository).to have_received(:branch_names).at_least(2).times
        expect(project.repository.gitaly_ref_client).to have_received(:branch_names).once

        expect_n_matching_branches_count_fields(4)
      end

      def expect_n_matching_branches_count_fields(count)
        branch_rule_nodes = graphql_data_at('project', 'branchRules', 'nodes')
        expect(branch_rule_nodes.count).to eq(count)
        branch_rule_nodes.each do |node|
          expect(node['matchingBranchesCount']).to be_present
        end
      end
    end

    describe 'response' do
      before do
        post_graphql(query, current_user: current_user, variables: variables)
      end

      it_behaves_like 'a working graphql query'

      it 'includes all fields', :aggregate_failures do
        # Responses will be sorted alphabetically. Branch names for this spec
        # come from an external constant so we check which is first
        br_a_idx = branch_name_a < branch_name_b ? 0 : 1
        br_b_idx = 1 - br_a_idx

        branch_rule_a_data = branch_rules_data.dig(br_a_idx, 'node')
        branch_rule_b_data = branch_rules_data.dig(br_b_idx, 'node')

        expect(branch_rule_a_data['name']).to eq(branch_name_a)
        expect(branch_rule_a_data['isDefault']).to be(true).or be(false)
        expect(branch_rule_a_data['branchProtection']).to be_present
        expect(branch_rule_a_data['matchingBranchesCount']).to eq(1)
        expect(branch_rule_a_data['createdAt']).to be_present
        expect(branch_rule_a_data['updatedAt']).to be_present

        wildcard_count = TestEnv::BRANCH_SHA.keys.count do |branch_name|
          branch_name.starts_with?('diff-')
        end
        expect(branch_rule_b_data['name']).to eq(branch_name_b)
        expect(branch_rule_b_data['isDefault']).to be(true).or be(false)
        expect(branch_rule_b_data['branchProtection']).to be_present
        expect(branch_rule_b_data['matchingBranchesCount']).to eq(wildcard_count)
        expect(branch_rule_b_data['createdAt']).to be_present
        expect(branch_rule_b_data['updatedAt']).to be_present
      end

      context 'when limiting the number of results' do
        let(:branch_rule_limit) { 1 }
        let(:variables) { { path: project.full_path, n: branch_rule_limit } }
        let(:next_variables) do
          { path: project.full_path, n: branch_rule_limit, cursor: last_cursor }
        end

        it_behaves_like 'a working graphql query'

        it 'returns pagination information' do
          expect(branch_rules_data.size).to eq(branch_rule_limit)
          expect(has_next_page).to be_truthy
          expect(has_prev_page).to be_falsey
          post_graphql(query, current_user: current_user, variables: next_variables)
          expect(branch_rules_data.size).to eq(branch_rule_limit)
          expect(has_next_page).to be_falsey
          expect(has_prev_page).to be_truthy
        end

        context 'when no limit is provided' do
          let(:branch_rule_limit) { nil }

          it 'returns all branch_rules' do
            expect(branch_rules_data.size).to eq(branch_rules.size)
          end
        end
      end
    end
  end

  def pagination_info
    graphql_data_at('project', 'branchRules', 'pageInfo')
  end

  def has_next_page
    pagination_info['hasNextPage']
  end

  def has_prev_page
    pagination_info['hasPreviousPage']
  end

  def last_cursor
    branch_rules_data.last['cursor']
  end
end
