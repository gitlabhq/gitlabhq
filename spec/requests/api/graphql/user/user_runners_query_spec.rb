# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Getting runners of the current user', feature_category: :fleet_visibility do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }

  let(:query) do
    graphql_query_for(:current_user, {}, user_fields)
  end

  let(:args) { nil }
  let(:user_fields) { query_nodes(:runners, %w[id description], args: args) }
  let(:path) { %i[current_user runners nodes] }

  subject(:user_runners) do
    post_graphql(query, current_user: current_user)
    graphql_data_at(*path)
  end

  include_context 'runners resolver setup'

  context 'when user has no runner access' do
    it 'returns empty list' do
      is_expected.to be_empty
    end
  end

  context 'with user as project maintainer' do
    before do
      project.add_maintainer(current_user)
    end

    it 'returns all runners available to the project' do
      is_expected.to contain_exactly(
        a_graphql_entity_for(inactive_project_runner),
        a_graphql_entity_for(offline_project_runner)
      )
    end
  end

  context 'with user as group owner' do
    before do
      group.add_owner(current_user)
    end

    it 'returns all runners available to the project' do
      is_expected.to contain_exactly(
        a_graphql_entity_for(inactive_project_runner),
        a_graphql_entity_for(offline_project_runner),
        a_graphql_entity_for(group_runner),
        a_graphql_entity_for(subgroup_runner)
      )
    end
  end

  context 'with assignableToProjectPath' do
    let_it_be(:other_project) { create(:project, group: group) }

    let_it_be(:other_project_runner_online) { create(:ci_runner, :project, :online, projects: [other_project]) }
    let_it_be(:other_project_runner_offline) { create(:ci_runner, :project, :offline, projects: [other_project]) }
    let_it_be(:other_project_runner_locked) { create(:ci_runner, :project, :locked, projects: [other_project]) }

    before do
      group.add_owner(current_user)
    end

    context 'with the argument' do
      let(:args) do
        { assignable_to_project_path: project.full_path }
      end

      it 'returns assignable runners' do
        is_expected.to contain_exactly(
          a_graphql_entity_for(other_project_runner_online),
          a_graphql_entity_for(other_project_runner_offline)
        )
      end
    end

    context 'when combined with other filters' do
      let(:args) do
        {
          status: :ONLINE,
          assignable_to_project_path: project.full_path
        }
      end

      it 'returns runners matching filters' do
        is_expected.to contain_exactly(
          a_graphql_entity_for(other_project_runner_online)
        )
      end
    end
  end
end
