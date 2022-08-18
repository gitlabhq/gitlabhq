# frozen_string_literal: true

RSpec.shared_examples 'lists move service' do
  shared_examples 'correct movement behavior' do
    context 'when list type is set to label' do
      it 'does not reorder lists when new position is nil' do
        service = described_class.new(parent, user, position: nil)

        service.execute(planning)

        expect(ordered_lists).to eq([planning, development, review, staging])
      end

      it 'does not reorder lists when new position is equal to old position' do
        service = described_class.new(parent, user, position: planning.position)

        service.execute(planning)

        expect(ordered_lists).to eq([planning, development, review, staging])
      end

      it 'does not reorder lists when new position is negative' do
        service = described_class.new(parent, user, position: -1)

        service.execute(planning)

        expect(ordered_lists).to eq([planning, development, review, staging])
      end

      it 'does not reorder lists when new position is bigger then last position' do
        service = described_class.new(parent, user, position: ordered_lists.last.position + 1)

        service.execute(planning)

        expect(ordered_lists).to eq([planning, development, review, staging])
      end

      it 'moves the list to the first position when new position is equal to first position' do
        service = described_class.new(parent, user, position: 0)

        service.execute(staging)

        expect(ordered_lists).to eq([staging, planning, development, review])
      end

      it 'moves the list to the last position when new position is equal to last position' do
        service = described_class.new(parent, user, position: board.lists.label.last.position)

        service.execute(planning)

        expect(ordered_lists).to eq([development, review, staging, planning])
      end

      it 'moves the list to the correct position when new position is greater than old position (third list)' do
        service = described_class.new(parent, user, position: review.position)

        service.execute(planning)

        expect(ordered_lists).to eq([development, review, planning, staging])
      end

      it 'moves the list to the correct position when new position is lower than old position (second list)' do
        service = described_class.new(parent, user, position: development.position)

        service.execute(staging)

        expect(ordered_lists).to eq([planning, staging, development, review])
      end
    end

    it 'keeps position of lists when list type is closed' do
      service = described_class.new(parent, user, position: 2)

      service.execute(closed)

      expect(ordered_lists).to eq([planning, development, review, staging])
    end
  end

  context 'with complete position sequence' do
    let!(:planning)    { create(:list, board: board, position: 0) }
    let!(:development) { create(:list, board: board, position: 1) }
    let!(:review)      { create(:list, board: board, position: 2) }
    let!(:staging)     { create(:list, board: board, position: 3) }
    let!(:closed)      { create(:closed_list, board: board) }

    it_behaves_like 'correct movement behavior'
  end

  context 'with corrupted position sequence' do
    let!(:planning)    { create(:list, board: board, position: 0) }
    let!(:staging)     { create(:list, board: board, position: 6) }
    let!(:development) { create(:list, board: board, position: 1) }
    let!(:review)      { create(:list, board: board, position: 4) }
    let!(:closed)      { create(:closed_list, board: board) }

    it_behaves_like 'correct movement behavior'
  end

  def ordered_lists
    board.lists.where.not(position: nil)
  end
end
