# frozen_string_literal: true

RSpec.shared_examples 'multiple and scoped issue boards' do |route_definition|
  let(:root_url) { route_definition.gsub(":id", board_parent.id.to_s) }

  context 'multiple issue boards' do
    before do
      board_parent.add_reporter(user)
      stub_licensed_features(multiple_group_issue_boards: true)
    end

    describe "POST #{route_definition}" do
      it 'creates a board' do
        post api(root_url, user), params: { name: "new board" }

        expect(response).to have_gitlab_http_status(:created)
        expect(response).to match_response_schema('public_api/v4/board', dir: "ee")
      end
    end

    describe "PUT #{route_definition}/:board_id" do
      let(:url) { "#{root_url}/#{board.id}" }

      it 'updates a board' do
        put api(url, user), params: { name: 'new name', weight: 4, labels: 'foo, bar' }

        expect(response).to have_gitlab_http_status(:ok)

        expect(response).to match_response_schema('public_api/v4/board', dir: "ee")

        board.reload

        expect(board.name).to eq('new name')
        expect(board.weight).to eq(4)
        expect(board.labels.map(&:title)).to contain_exactly('foo', 'bar')
      end

      it 'does not remove missing attributes from the board' do
        expect { put api(url, user), params: { name: 'new name' } }
          .to not_change { board.reload.assignee }
          .and not_change { board.reload.milestone }
          .and not_change { board.reload.weight }
          .and not_change { board.reload.labels.map(&:title).sort }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/board', dir: "ee")
      end

      it 'allows removing optional attributes' do
        put api(url, user), params: { name: 'new name', assignee_id: nil, milestone_id: nil, weight: nil, labels: nil }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/board', dir: "ee")

        board.reload

        expect(board.name).to eq('new name')
        expect(board.assignee).to be_nil
        expect(board.milestone).to be_nil
        expect(board.weight).to be_nil
        expect(board.labels).to be_empty
      end
    end

    describe "DELETE #{route_definition}/:board_id" do
      let(:url) { "#{root_url}/#{board.id}" }

      it 'deletes a board' do
        delete api(url, user)

        expect(response).to have_gitlab_http_status(:no_content)
      end
    end
  end

  context 'with the scoped_issue_board-feature available' do
    it 'returns the milestone when the `scoped_issue_board` feature is enabled' do
      stub_licensed_features(scoped_issue_board: true)

      get api(root_url, user)

      expect(json_response.first["milestone"]).not_to be_nil
    end

    it 'hides the milestone when the `scoped_issue_board` feature is disabled' do
      stub_licensed_features(scoped_issue_board: false)

      get api(root_url, user)

      expect(json_response.first["milestone"]).to be_nil
    end
  end
end
