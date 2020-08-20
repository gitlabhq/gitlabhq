# frozen_string_literal: true

RSpec.shared_examples 'lists list service' do
  context 'when the board has a backlog list' do
    let!(:backlog_list) { create(:backlog_list, board: board) }

    it 'does not create a backlog list' do
      expect { service.execute(board) }.not_to change(board.lists, :count)
    end

    it "returns board's lists" do
      expect(service.execute(board)).to eq [backlog_list, list, board.closed_list]
    end
  end

  context 'when the board does not have a backlog list' do
    it 'creates a backlog list' do
      expect { service.execute(board) }.to change(board.lists, :count).by(1)
    end

    it 'does not create a backlog list when create_default_lists is false' do
      expect { service.execute(board, create_default_lists: false) }.not_to change(board.lists, :count)
    end

    it "returns board's lists" do
      expect(service.execute(board)).to eq [board.backlog_list, list, board.closed_list]
    end
  end

  context 'when wanting a specific list' do
    let!(:list1) { create(:list, board: board) }

    it 'returns list specified by id' do
      service = described_class.new(parent, user, list_id: list1.id)

      expect(service.execute(board, create_default_lists: false)).to eq [list1]
    end

    it 'returns empty result when list is not found' do
      external_board = create(:board, resource_parent: create(:project))
      external_list = create(:list, board: external_board)
      service = described_class.new(parent, user, list_id: external_list.id)

      expect(service.execute(board, create_default_lists: false)).to eq(List.none)
    end
  end
end
