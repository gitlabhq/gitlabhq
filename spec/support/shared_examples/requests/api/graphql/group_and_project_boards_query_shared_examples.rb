# frozen_string_literal: true

RSpec.shared_examples 'group and project boards query' do
  include GraphqlHelpers

  it_behaves_like 'a working graphql query' do
    before do
      post_graphql(query, current_user: current_user)
    end
  end

  context 'when the user does not have access to the board parent' do
    it 'returns nil' do
      create(:board, resource_parent: board_parent, name: 'A')

      post_graphql(query)

      expect(graphql_data[board_parent_type]).to be_nil
    end
  end

  context 'when no permission to read board' do
    it 'does not return any boards' do
      board_parent.add_guest(current_user)
      board = create(:board, resource_parent: board_parent, name: 'A')

      allow(Ability).to receive(:allowed?).and_call_original
      allow(Ability).to receive(:allowed?).with(user, :read_issue_board, board).and_return(false)

      post_graphql(query, current_user: current_user)

      expect(boards_data).to be_empty
    end
  end

  context 'when user can read the board parent' do
    before do
      board_parent.add_reporter(current_user)
    end

    it 'does not create a default board' do
      post_graphql(query, current_user: current_user)

      expect(boards_data).to be_empty
    end

    describe 'sorting and pagination' do
      let(:data_path) { [board_parent_type, :boards] }

      def pagination_query(params)
        graphql_query_for(board_parent_type, { full_path: board_parent.full_path },
          query_nodes(:boards, :id, include_pagination_info: true, args: params)
        )
      end

      context 'when using default sorting' do
        # rubocop:disable RSpec/VariableName
        let!(:board_B) { create(:board, resource_parent: board_parent, name: 'B') }
        let!(:board_C) { create(:board, resource_parent: board_parent, name: 'C') }
        let!(:board_a) { create(:board, resource_parent: board_parent, name: 'a') }
        let!(:board_A) { create(:board, resource_parent: board_parent, name: 'A') }
        let(:boards)   { [board_a, board_A, board_B, board_C] }
        # rubocop:enable RSpec/VariableName

        context 'when ascending' do
          it_behaves_like 'sorted paginated query' do
            include_context 'no sort argument'

            let(:first_param) { 2 }

            def pagination_results_data(nodes)
              nodes
            end

            let(:all_records) do
              if board_parent.multiple_issue_boards_available?
                boards.map { |board| a_graphql_entity_for(board) }
              else
                [a_graphql_entity_for(boards.first)]
              end
            end
          end
        end
      end
    end
  end

  context 'when querying for a single board' do
    before do
      board_parent.add_reporter(current_user)
    end

    it_behaves_like 'a working graphql query' do
      before do
        post_graphql(query_single_board("id: \"gid://gitlab/Board/1\""), current_user: current_user)
      end
    end

    it 'finds the correct board' do
      board = create(:board, resource_parent: board_parent, name: 'A')

      post_graphql(query_single_board("id: \"#{global_id_of(board)}\""), current_user: current_user)

      expect(board_data['name']).to eq board.name
    end
  end
end
