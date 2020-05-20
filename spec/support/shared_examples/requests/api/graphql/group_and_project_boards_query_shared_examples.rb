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
      allow(Ability).to receive(:allowed?).with(user, :read_board, board).and_return(false)

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
      context 'when using default sorting' do
        let!(:board_B) { create(:board, resource_parent: board_parent, name: 'B') }
        let!(:board_C) { create(:board, resource_parent: board_parent, name: 'C') }
        let!(:board_a) { create(:board, resource_parent: board_parent, name: 'a') }
        let!(:board_A) { create(:board, resource_parent: board_parent, name: 'A') }

        before do
          post_graphql(query, current_user: current_user)
        end

        it_behaves_like 'a working graphql query'

        context 'when ascending' do
          let(:boards) { [board_a, board_A, board_B, board_C] }
          let(:expected_boards) do
            if board_parent.multiple_issue_boards_available?
              boards
            else
              [boards.first]
            end
          end

          it 'sorts boards' do
            expect(grab_names).to eq expected_boards.map(&:name)
          end

          context 'when paginating' do
            let(:params) { 'first: 2' }

            it 'sorts boards' do
              expect(grab_names).to eq expected_boards.first(2).map(&:name)

              cursored_query = query("after: \"#{end_cursor}\"")
              post_graphql(cursored_query, current_user: current_user)

              response_data = Gitlab::Json.parse(response.body)['data'][board_parent_type]['boards']['edges']

              expect(grab_names(response_data)).to eq expected_boards.drop(2).first(2).map(&:name)
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
        post_graphql(query_single_board, current_user: current_user)
      end
    end

    it 'finds the correct board' do
      board = create(:board, resource_parent: board_parent, name: 'A')

      post_graphql(query_single_board("id: \"#{global_id_of(board)}\""), current_user: current_user)

      expect(board_data['name']).to eq board.name
    end
  end
end
