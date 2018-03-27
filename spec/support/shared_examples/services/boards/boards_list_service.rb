shared_examples 'boards list service' do
  context 'when parent does not have a board' do
    it 'creates a new parent board' do
      expect { service.execute }.to change(parent.boards, :count).by(1)
    end

    it 'delegates the parent board creation to Boards::CreateService' do
      expect_any_instance_of(Boards::CreateService).to receive(:execute).once

      service.execute
    end
  end

  context 'when parent has a board' do
    before do
      create(:board, parent: parent)
    end

    it 'does not create a new board' do
      expect { service.execute }.not_to change(parent.boards, :count)
    end
  end

  it 'returns parent boards' do
    board = create(:board, parent: parent)

    expect(service.execute).to eq [board]
  end
end
