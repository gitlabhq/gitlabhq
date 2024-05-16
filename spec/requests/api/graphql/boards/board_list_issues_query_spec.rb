# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'get board lists', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:user)           { create(:user) }
  let_it_be(:unauth_user)    { create(:user) }
  let_it_be(:project)        { create(:project, creator_id: user.id, namespace: user.namespace) }
  let_it_be(:group)          { create(:group, :private) }
  let_it_be(:project_label)  { create(:label, project: project, name: 'Development') }
  let_it_be(:project_label2) { create(:label, project: project, name: 'Testing') }
  let_it_be(:group_label)    { create(:group_label, group: group, name: 'Development') }
  let_it_be(:group_label2)   { create(:group_label, group: group, name: 'Testing') }

  let(:params)            { '' }
  let(:board)             {}
  let(:confidential)      { false }
  let(:board_parent_type) { board_parent.class.to_s.downcase }
  let(:board_data)        { graphql_data[board_parent_type]['boards']['nodes'][0] }
  let(:lists_data)        { board_data['lists']['nodes'][1] }
  let(:issues_data)       { lists_data['issues']['nodes'] }
  let(:issue_params)      { { filters: { label_name: label2.title, confidential: confidential }, first: 3 } }

  def query(list_params = params)
    graphql_query_for(
      board_parent_type,
      { 'fullPath' => board_parent.full_path },
      <<~BOARDS
        boards(first: 1) {
          nodes {
            lists {
              nodes {
                issues(#{attributes_to_graphql(issue_params)}) {
                  count
                  nodes {
                    #{all_graphql_fields_for('issues'.classify)}
                  }
                }
              }
            }
          }
        }
    BOARDS
    )
  end

  def issue_id
    issues_data.map { |i| i['id'] }
  end

  def issue_titles
    issues_data.map { |i| i['title'] }
  end

  def issue_relative_positions
    issues_data.map { |i| i['relativePosition'] }
  end

  shared_examples 'group and project board list issues query' do
    let_it_be(:board) { create(:board, resource_parent: board_parent) }
    let_it_be(:label_list) { create(:list, board: board, label: label, position: 10) }
    let_it_be(:issue1) { create(:issue, project: issue_project, labels: [label, label2], relative_position: 9) }
    let_it_be(:issue2) { create(:issue, project: issue_project, labels: [label, label2], relative_position: 2) }
    let_it_be(:issue3) { create(:issue, project: issue_project, labels: [label, label2], relative_position: nil) }
    let_it_be(:issue4) { create(:issue, project: issue_project, labels: [label], relative_position: 9) }
    let_it_be(:issue5) { create(:issue, project: issue_project, labels: [label2], relative_position: 432) }
    let_it_be(:issue6) { create(:issue, project: issue_project, labels: [label, label2], relative_position: nil) }
    let_it_be(:issue7) { create(:issue, project: issue_project, labels: [label, label2], relative_position: 5, confidential: true) }

    context 'when the user does not have access to the board' do
      it 'returns nil' do
        post_graphql(query, current_user: unauth_user)

        expect(graphql_data[board_parent_type]).to be_nil
      end
    end

    context 'when user can read the board' do
      before_all do
        board_parent.add_reporter(user)
      end

      subject { post_graphql(query("id: \"#{global_id_of(label_list)}\""), current_user: user) }

      it 'can access the issues', :aggregate_failures do
        subject

        # ties for relative positions are broken by id in ascending order by default
        expect(issue_titles).to eq([issue2.title, issue1.title, issue3.title])
        expect(issue_relative_positions).not_to include(nil)
      end

      it 'does not set the relative positions of the issues not being returned', :aggregate_failures do
        subject

        expect(issue_id).not_to include(issue6.id)
        expect(issue3.relative_position).to be_nil
      end

      context 'when filtering by confidential' do
        let(:confidential) { true }

        it 'returns matching issue' do
          subject

          expect(issue_titles).to match_array([issue7.title])
          expect(issue_relative_positions).not_to include(nil)
        end
      end

      context 'when filtering by a unioned argument' do
        let(:another_user) { create(:user) }
        let(:issue_params) { { filters: { or: { assignee_usernames: [user.username, another_user.username] } } } }

        it 'returns correctly filtered issues' do
          IssueAssignee.create!(issue_id: issue1.id, user_id: user.id)
          IssueAssignee.create!(issue_id: issue2.id, user_id: another_user.id)

          subject

          expect(issue_id).to contain_exactly(issue1.to_gid.to_s, issue2.to_gid.to_s)
        end
      end
    end
  end

  describe 'for a project' do
    let_it_be(:board_parent) { project }
    let_it_be(:label) { project_label }
    let_it_be(:label2) { project_label2 }
    let_it_be(:issue_project) { project }

    it_behaves_like 'group and project board list issues query'
  end

  describe 'for a group' do
    let_it_be(:board_parent) { group }
    let_it_be(:label) { group_label }
    let_it_be(:label2) { group_label2 }

    let_it_be(:issue_project) { create(:project, :private, group: group) }

    before do
      allow(board_parent).to receive(:multiple_issue_boards_available?).and_return(false)
    end

    it_behaves_like 'group and project board list issues query'
  end
end
