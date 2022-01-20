# frozen_string_literal: true

RSpec.shared_examples 'querying a GraphQL type recent boards' do
  describe 'Get list of recently visited boards' do
    let(:boards_data) { graphql_data[board_type]['recentIssueBoards']['nodes'] }

    context 'when the request is correct' do
      before do
        visit_board
        parent.add_reporter(user)
        post_graphql(query, current_user: user)
      end

      it_behaves_like 'a working graphql query'

      it 'returns recent boards for user successfully' do
        expect(response).to have_gitlab_http_status(:ok)
        expect(graphql_errors).to be_nil
        expect(boards_data.size).to eq(1)
        expect(boards_data[0]['name']).to eq(board.name)
      end
    end

    context 'when requests has errors' do
      context 'when there are no recently visited boards' do
        it 'returns empty result' do
          post_graphql(query, current_user: user)

          expect(response).to have_gitlab_http_status(:success)
          expect(graphql_errors).to be_nil
          expect(boards_data).to be_empty
        end
      end
    end
  end

  def query(query_params: {}, full_path: parent.full_path)
    board_nodes = <<~NODE
      nodes {
        name
      }
    NODE

    graphql_query_for(
      board_type.to_sym,
      { full_path: full_path },
      query_graphql_field(:recent_issue_boards, query_params, board_nodes)
    )
  end

  def visit_board
    if board_type == 'group'
      create(:board_group_recent_visit, group: parent, board: board, user: user)
    else
      create(:board_project_recent_visit, project: parent, board: board, user: user)
    end
  end
end
