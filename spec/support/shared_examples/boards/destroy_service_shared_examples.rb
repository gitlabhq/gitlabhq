# frozen_string_literal: true

RSpec.shared_examples 'board destroy service' do
  describe '#execute' do
    let(:parent_type) { parent.is_a?(Project) ? :project : :group }
    let!(:board) { create(board_factory, parent_type => parent) }

    subject(:service) { described_class.new(parent, double) }

    context 'when there is more than one board' do
      let!(:board2) { create(board_factory, parent_type => parent) }

      it 'destroys the board' do
        create(board_factory, parent_type => parent)

        expect do
          expect(service.execute(board)).to be_success
        end.to change { boards.count }.by(-1)
      end
    end

    context 'when there is only one board' do
      it 'does remove board' do
        expect do
          service.execute(board)
        end.to change { boards.count }.by(-1)
      end
    end
  end
end
