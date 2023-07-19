# frozen_string_literal: true

RSpec.shared_examples 'lists list service' do
  context 'when the board has a backlog list' do
    let(:backlog_list) { board.lists.backlog.first }

    it 'does not create a backlog list' do
      expect { service.execute(board) }.not_to change { board.lists.count }
    end

    it "returns board's lists" do
      expect(service.execute(board)).to eq [backlog_list, list, board.lists.closed.first]
    end

    context 'when hide_backlog_list is true' do
      before do
        board.update_column(:hide_backlog_list, true)
      end

      it 'hides backlog list' do
        expect(service.execute(board)).to match_array([board.lists.closed.first, list])
      end
    end

    context 'when hide_closed_list is true' do
      before do
        board.update_column(:hide_closed_list, true)
      end

      it 'hides closed list' do
        expect(service.execute(board)).to match_array([backlog_list, list])
      end
    end
  end

  context 'when the board does not have a backlog list' do
    before do
      board.lists.backlog.delete_all
    end

    it 'creates a backlog list' do
      expect { service.execute(board) }.to change { board.lists.count }.by(1)
    end

    it 'does not create a backlog list when create_default_lists is false' do
      expect { service.execute(board, create_default_lists: false) }.not_to change { board.lists.count }
    end

    it "returns board's lists" do
      expect(service.execute(board)).to eq [board.lists.backlog.first, list, board.lists.closed.first]
    end
  end

  context 'when wanting a specific list' do
    it 'returns list specified by id' do
      service = described_class.new(parent, user, list_id: list.id)

      expect(service.execute(board, create_default_lists: false)).to eq [list]
    end

    it 'returns empty result when list is not found' do
      service = described_class.new(parent, user, list_id: unrelated_list.id)

      expect(service.execute(board, create_default_lists: false)).to be_empty
    end
  end
end
