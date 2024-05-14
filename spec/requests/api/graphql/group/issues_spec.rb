# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting an issue list for a group', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:group1) { create(:group) }
  let_it_be(:group2) { create(:group) }
  let_it_be(:project1) { create(:project, :public, group: group1) }
  let_it_be(:project2) { create(:project, :private, group: group1) }
  let_it_be(:project3) { create(:project, :public, group: group2) }
  let_it_be(:issue1) { create(:issue, project: project1) }
  let_it_be(:issue2) { create(:issue, project: project2) }
  let_it_be(:issue3) { create(:issue, project: project3) }

  let(:issue1_gid) { issue1.to_global_id.to_s }
  let(:issue2_gid) { issue2.to_global_id.to_s }
  let(:issues_data) { graphql_data['group']['issues']['edges'] }
  let(:issue_filter_params) { {} }

  let(:fields) do
    <<~QUERY
    edges {
      node {
        #{all_graphql_fields_for('issues'.classify)}
      }
    }
    QUERY
  end

  let(:query) do
    graphql_query_for(
      'group',
      { 'fullPath' => group1.full_path },
      query_graphql_field('issues', issue_filter_params, fields)
    )
  end

  it_behaves_like 'a working graphql query' do
    before do
      post_graphql(query, current_user: current_user)
    end
  end

  context 'when there are archived projects' do
    let_it_be(:archived_project) { create(:project, :archived, group: group1) }
    let_it_be(:archived_issue)   { create(:issue, project: archived_project) }

    before_all do
      group1.add_developer(current_user)
    end

    it 'excludes issues from archived projects by default' do
      post_graphql(query, current_user: current_user)

      expect(issues_ids).to contain_exactly(issue1_gid, issue2_gid)
    end

    context 'when include_archived is true' do
      let(:issue_filter_params) { { include_archived: true } }

      it 'includes issues from archived projects' do
        post_graphql(query, current_user: current_user)

        expect(issues_ids).to contain_exactly(issue1_gid, issue2_gid, archived_issue.to_global_id.to_s)
      end
    end
  end

  context 'when there is a confidential issue' do
    let_it_be(:confidential_issue1) { create(:issue, :confidential, project: project1) }
    let_it_be(:confidential_issue2) { create(:issue, :confidential, project: project2) }
    let_it_be(:confidential_issue3) { create(:issue, :confidential, project: project3) }

    let(:confidential_issue1_gid) { confidential_issue1.to_global_id.to_s }
    let(:confidential_issue2_gid) { confidential_issue2.to_global_id.to_s }

    context 'when the user cannot see confidential issues' do
      before do
        group1.add_guest(current_user)
      end

      it 'returns issues without confidential issues for the group' do
        post_graphql(query, current_user: current_user)

        expect(issues_ids).to contain_exactly(issue1_gid, issue2_gid)
      end

      context 'filtering for confidential issues' do
        let(:issue_filter_params) { { confidential: true } }

        it 'returns no issues' do
          post_graphql(query, current_user: current_user)

          expect(issues_ids).to be_empty
        end
      end

      context 'filtering for non-confidential issues' do
        let(:issue_filter_params) { { confidential: false } }

        it 'returns correctly filtered issues' do
          post_graphql(query, current_user: current_user)

          expect(issues_ids).to contain_exactly(issue1_gid, issue2_gid)
        end
      end
    end

    context 'when the user can see confidential issues' do
      before do
        group1.add_developer(current_user)
      end

      it 'returns issues with confidential issues for the group' do
        post_graphql(query, current_user: current_user)

        expect(issues_ids).to contain_exactly(issue1_gid, issue2_gid, confidential_issue1_gid, confidential_issue2_gid)
      end

      context 'filtering for confidential issues' do
        let(:issue_filter_params) { { confidential: true } }

        it 'returns correctly filtered issues' do
          post_graphql(query, current_user: current_user)

          expect(issues_ids).to contain_exactly(confidential_issue1_gid, confidential_issue2_gid)
        end
      end

      context 'filtering for non-confidential issues' do
        let(:issue_filter_params) { { confidential: false } }

        it 'returns correctly filtered issues' do
          post_graphql(query, current_user: current_user)

          expect(issues_ids).to contain_exactly(issue1_gid, issue2_gid)
        end
      end
    end
  end

  def issues_ids
    graphql_dig_at(issues_data, :node, :id)
  end
end
