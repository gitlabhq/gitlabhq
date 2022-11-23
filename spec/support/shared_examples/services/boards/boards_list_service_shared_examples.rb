# frozen_string_literal: true

RSpec.shared_examples 'boards list service' do
  it 'does not create a new board' do
    expect { service.execute }.not_to change { parent.boards.count }
  end

  it 'returns parent boards' do
    board = create(:board, resource_parent: parent)

    expect(service.execute).to eq [board]
  end
end

RSpec.shared_examples 'multiple boards list service' do
  # rubocop:disable RSpec/VariableName
  let(:service)  { described_class.new(parent, double) }
  let!(:board_B) { create(:board, resource_parent: parent, name: 'B-board') }
  let!(:board_c) { create(:board, resource_parent: parent, name: 'c-board') }
  let!(:board_a) { create(:board, resource_parent: parent, name: 'a-board') }
  # rubocop:enable RSpec/VariableName

  describe '#execute' do
    it 'returns all issue boards' do
      expect(service.execute.size).to eq(3)
    end

    it 'returns boards ordered by name' do
      expect(service.execute).to eq [board_a, board_B, board_c]
    end

    context 'when wanting a specific board' do
      it 'returns board specified by id' do
        service = described_class.new(parent, double, board_id: board_c.id)

        expect(service.execute).to eq [board_c]
      end

      it 'raises exception when board is not found' do
        outside_board = create(:board, resource_parent: create(:project), name: 'outside board')
        service = described_class.new(parent, double, board_id: outside_board.id)

        expect { service.execute }.to raise_exception(ActiveRecord::RecordNotFound)
      end
    end
  end
end
