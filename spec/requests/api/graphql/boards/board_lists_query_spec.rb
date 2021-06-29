# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'get board lists' do
  include GraphqlHelpers

  let_it_be(:user)           { create(:user) }
  let_it_be(:unauth_user)    { create(:user) }
  let_it_be(:group)          { create(:group, :private) }
  let_it_be(:project)        { create(:project, creator_id: user.id, group: group) }
  let_it_be(:project_label)  { create(:label, project: project, name: 'Development') }
  let_it_be(:project_label2) { create(:label, project: project, name: 'Testing') }
  let_it_be(:group_label)    { create(:group_label, group: group, name: 'Development') }
  let_it_be(:group_label2)   { create(:group_label, group: group, name: 'Testing') }

  let(:params)            { '' }
  let(:board)             { }
  let(:board_parent_type) { board_parent.class.to_s.downcase }
  let(:board_data)        { graphql_data[board_parent_type]['boards']['edges'].first['node'] }
  let(:lists_data)        { board_data['lists']['edges'] }
  let(:start_cursor)      { board_data['lists']['pageInfo']['startCursor'] }
  let(:end_cursor)        { board_data['lists']['pageInfo']['endCursor'] }

  def query(list_params = params)
    graphql_query_for(
      board_parent_type,
      { 'fullPath' => board_parent.full_path },
      <<~BOARDS
        boards(first: 1) {
          edges {
            node {
              #{field_with_params('lists', list_params)} {
                pageInfo {
                  startCursor
                  endCursor
                }
                edges {
                  node {
                    #{all_graphql_fields_for('board_lists'.classify)}
                  }
                }
              }
            }
          }
        }
    BOARDS
    )
  end

  shared_examples 'group and project board lists query' do
    let!(:board) { create(:board, resource_parent: board_parent) }

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

      describe 'sorting and pagination' do
        let_it_be(:current_user) { user }

        let(:data_path) { [board_parent_type, :boards, :nodes, 0, :lists] }

        def pagination_query(params)
          graphql_query_for(
            board_parent_type,
            { 'fullPath' => board_parent.full_path },
            <<~BOARDS
              boards(first: 1) {
                nodes {
                  #{query_graphql_field(:lists, params, "#{page_info} nodes { id }")}
                }
              }
            BOARDS
          )
        end

        context 'when using default sorting' do
          let!(:label_list)   { create(:list, board: board, label: label, position: 10) }
          let!(:label_list2)  { create(:list, board: board, label: label2, position: 2) }
          let!(:backlog_list) { create(:backlog_list, board: board) }
          let(:closed_list)   { board.lists.find_by(list_type: :closed) }
          let(:lists)         { [backlog_list, label_list2, label_list, closed_list] }

          context 'when ascending' do
            it_behaves_like 'sorted paginated query' do
              let(:sort_param)       { }
              let(:first_param)      { 2 }
              let(:expected_results) { lists.map { |list| global_id_of(list) } }
            end
          end
        end
      end
    end

    context 'when querying for a single list' do
      before do
        board_parent.add_reporter(user)
      end

      it 'returns the correct list with issue count for matching issue filters' do
        label_list = create(:list, board: board, label: label, position: 10)
        create(:issue, project: project, labels: [label, label2])
        create(:issue, project: project, labels: [label])

        post_graphql(query(id: global_id_of(label_list), issueFilters: { labelName: label2.title }), current_user: user)

        aggregate_failures do
          list_node = lists_data[0]['node']

          expect(list_node['title']).to eq label_list.title
          expect(list_node['issuesCount']).to eq 1
        end
      end
    end
  end

  describe 'for a project' do
    let(:board_parent) { project }
    let(:label) { project_label }
    let(:label2) { project_label2 }

    it_behaves_like 'group and project board lists query'
  end

  describe 'for a group' do
    let(:board_parent) { group }
    let(:label) { group_label }
    let(:label2) { group_label2 }

    before do
      allow(board_parent).to receive(:multiple_issue_boards_available?).and_return(false)
    end

    it_behaves_like 'group and project board lists query'
  end
end
