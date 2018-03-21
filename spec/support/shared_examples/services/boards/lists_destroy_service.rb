shared_examples 'lists destroy service' do
  context 'when list type is label' do
    it 'removes list from board' do
      list = create(:list, board: board)
      service = described_class.new(parent, user)

      expect { service.execute(list) }.to change(board.lists, :count).by(-1)
    end

    it 'decrements position of higher lists' do
      development = create(:list, board: board, position: 0)
      review      = create(:list, board: board, position: 1)
      staging     = create(:list, board: board, position: 2)
      closed      = board.closed_list

      described_class.new(parent, user).execute(development)

      expect(review.reload.position).to eq 0
      expect(staging.reload.position).to eq 1
      expect(closed.reload.position).to be_nil
    end
  end

  it 'does not remove list from board when list type is closed' do
    list = board.closed_list
    service = described_class.new(parent, user)

    expect { service.execute(list) }.not_to change(board.lists, :count)
  end
end
