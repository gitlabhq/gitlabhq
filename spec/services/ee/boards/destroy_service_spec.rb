require 'spec_helper'

describe Boards::DestroyService, services: true do
  describe '#execute' do
    let(:group) { create(:group) }
    let!(:board)  { create(:board, group: group) }

    subject(:service) { described_class.new(group, double) }

    context 'when group have more than one board' do
      it 'removes board from group' do
        create(:board, group: group)

        expect { service.execute(board) }.to change(group.boards, :count).by(-1)
      end
    end

    context 'when group have one board' do
      it 'does not remove board from group' do
        expect { service.execute(board) }.not_to change(group.boards, :count)
      end
    end
  end
end
