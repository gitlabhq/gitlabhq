# frozen_string_literal: true

RSpec.shared_context 'group and project boards query context' do
  let_it_be(:user) { create :user }
  let(:current_user) { user }
  let(:params) { '' }
  let(:board_parent_type) { board_parent.class.to_s.downcase }
  let(:boards_data) { graphql_data[board_parent_type]['boards']['edges'] }
  let(:board_data) { graphql_data[board_parent_type]['board'] }
  let(:start_cursor) { graphql_data[board_parent_type]['boards']['pageInfo']['startCursor'] }
  let(:end_cursor) { graphql_data[board_parent_type]['boards']['pageInfo']['endCursor'] }

  def query(board_params = params)
    graphql_query_for(
      board_parent_type,
      { 'fullPath' => board_parent.full_path },
      <<~BOARDS
        #{field_with_params('boards', board_params)} {
          pageInfo {
            startCursor
            endCursor
          }
          edges {
            node {
              #{all_graphql_fields_for('boards'.classify)}
            }
          }
        }
    BOARDS
    )
  end

  def query_single_board(board_params = params)
    graphql_query_for(
      board_parent_type,
      { 'fullPath' => board_parent.full_path },
      <<~BOARD
        #{field_with_params('board', board_params)} {
          #{all_graphql_fields_for('board'.classify)}
        }
      BOARD
    )
  end

  def grab_names(data = boards_data)
    data.map do |board|
      board.dig('node', 'name')
    end
  end
end
