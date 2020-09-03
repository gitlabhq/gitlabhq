# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'get board lists' do
  include GraphqlHelpers

  let_it_be(:user)           { create(:user) }
  let_it_be(:unauth_user)    { create(:user) }
  let_it_be(:project)        { create(:project, creator_id: user.id, namespace: user.namespace ) }
  let_it_be(:group)          { create(:group, :private) }
  let_it_be(:project_label)  { create(:label, project: project, name: 'Development') }
  let_it_be(:project_label2) { create(:label, project: project, name: 'Testing') }
  let_it_be(:group_label)    { create(:group_label, group: group, name: 'Development') }
  let_it_be(:group_label2)   { create(:group_label, group: group, name: 'Testing') }

  let(:params)            { '' }
  let(:board)             { }
  let(:board_parent_type) { board_parent.class.to_s.downcase }
  let(:board_data)        { graphql_data[board_parent_type]['boards']['nodes'][0] }
  let(:lists_data)        { board_data['lists']['nodes'][0] }
  let(:issues_data)       { lists_data['issues']['nodes'] }

  def query(list_params = params)
    graphql_query_for(
      board_parent_type,
      { 'fullPath' => board_parent.full_path },
      <<~BOARDS
        boards(first: 1) {
          nodes {
            lists {
              nodes {
                issues(filters: {labelName: "#{label2.title}"}) {
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

  def issue_titles
    issues_data.map { |i| i['title'] }
  end

  shared_examples 'group and project board list issues query' do
    let!(:board) { create(:board, resource_parent: board_parent) }
    let!(:label_list) { create(:list, board: board, label: label, position: 10) }
    let!(:issue1) { create(:issue, project: issue_project, labels: [label, label2], relative_position: 9) }
    let!(:issue2) { create(:issue, project: issue_project, labels: [label, label2], relative_position: 2) }
    let!(:issue3) { create(:issue, project: issue_project, labels: [label], relative_position: 9) }
    let!(:issue4) { create(:issue, project: issue_project, labels: [label2], relative_position: 432) }

    context 'when the user does not have access to the board' do
      it 'returns nil' do
        post_graphql(query, current_user: unauth_user)

        expect(graphql_data[board_parent_type]).to be_nil
      end
    end

    context 'when user can read the board' do
      before do
        board_parent.add_reporter(user)
      end

      it 'can access the issues' do
        post_graphql(query("id: \"#{global_id_of(label_list)}\""), current_user: user)

        expect(issue_titles).to eq([issue2.title, issue1.title])
      end
    end
  end

  describe 'for a project' do
    let(:board_parent) { project }
    let(:label) { project_label }
    let(:label2) { project_label2 }
    let(:issue_project) { project }

    it_behaves_like 'group and project board list issues query'
  end

  describe 'for a group' do
    let(:board_parent) { group }
    let(:label) { group_label }
    let(:label2) { group_label2 }
    let(:issue_project) { create(:project, :private, group: group) }

    before do
      allow(board_parent).to receive(:multiple_issue_boards_available?).and_return(false)
    end

    it_behaves_like 'group and project board list issues query'
  end
end
