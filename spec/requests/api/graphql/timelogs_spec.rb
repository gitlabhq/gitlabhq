# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Timelogs', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, reporters: user) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:user_project) { create(:project, reporters: user) }

  let_it_be(:user_issue) { create(:issue, project: user_project) }
  let_it_be(:group_issue) { create(:issue, project: create(:project, group: group)) }
  let_it_be(:project_issue) { create(:issue, project: project) }

  let_it_be(:user_timelog) { create(:timelog, user: user, issue: user_issue) }
  let_it_be(:group_timelog) { create(:timelog, issue: group_issue) }
  let_it_be(:project_timelog) { create(:timelog, issue: project_issue) }

  let(:params) { {} }
  let(:group_id) { "gid://gitlab/Group/#{group.id}" }
  let(:project_id) { "gid://gitlab/Project/#{project.id}" }
  let(:current_user) { user }

  subject(:execute_query) { post_graphql(query, current_user: current_user) }

  shared_examples 'an OK response with no errors' do
    it 'returns no error message' do
      execute_query

      expect(response).to have_gitlab_http_status(:ok)
      expect(graphql_errors).to be_nil
    end
  end

  shared_examples 'a response containing the correct timelogs' do
    it 'returns the expected timelogs' do
      execute_query

      expect(graphql_data_at(:timelogs, :nodes).pluck('id')).to match_array(expected_timelogs)
    end
  end

  context 'with no parameters' do
    context 'when not an admin' do
      it 'returns an error message' do
        execute_query

        expect(response).to have_gitlab_http_status(:ok)
        expect(graphql_errors).to contain_exactly(
          a_hash_including('message' => 'Non-admin users must provide a group_id, project_id, or current username')
        )
      end
    end

    context 'when an admin' do
      let!(:current_user) { create(:user, :admin) }

      it_behaves_like 'an OK response with no errors'
    end
  end

  context 'with group_id parameter' do
    let(:params) { { group_id: group_id } }
    let(:expected_timelogs) do
      [
        "gid://gitlab/Timelog/#{project_timelog.id}",
        "gid://gitlab/Timelog/#{group_timelog.id}"
      ]
    end

    it_behaves_like 'an OK response with no errors'
    it_behaves_like 'a response containing the correct timelogs'
  end

  context 'with project_id parameter' do
    let(:params) { { project_id: project_id } }
    let(:expected_timelogs) { ["gid://gitlab/Timelog/#{project_timelog.id}"] }

    it_behaves_like 'an OK response with no errors'
    it_behaves_like 'a response containing the correct timelogs'
  end

  context 'with username parameter' do
    context 'when current user' do
      let(:params) { { username: user.username } }
      let(:expected_timelogs) { ["gid://gitlab/Timelog/#{user_timelog.id}"] }

      it_behaves_like 'an OK response with no errors'
      it_behaves_like 'a response containing the correct timelogs'
    end

    context 'when not current user' do
      let(:params) { { username: 'username' } }

      it 'returns an error message' do
        execute_query

        expect(response).to have_gitlab_http_status(:ok)
        expect(graphql_errors).to contain_exactly(
          a_hash_including('message' => 'Non-admin users must provide a group_id, project_id, or current username')
        )
      end
    end
  end

  def query
    timelog_nodes = <<~NODE
      nodes {
        id
      }
    NODE

    graphql_query_for(
      :timelogs,
      { **params },
      timelog_nodes
    )
  end
end
