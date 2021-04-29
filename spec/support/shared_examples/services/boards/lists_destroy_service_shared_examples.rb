# frozen_string_literal: true

RSpec.shared_examples 'lists destroy service' do
  context 'when list type is label' do
    it 'removes list from board' do
      service = described_class.new(parent, user)

      expect { service.execute(list) }.to change(board.lists, :count).by(-1)
    end

    it 'decrements position of higher lists' do
      development = create(list_type, params.merge(position: 0))
      review      = create(list_type, params.merge(position: 1))
      staging     = create(list_type, params.merge(position: 2))

      described_class.new(parent, user).execute(development)

      expect(review.reload.position).to eq 0
      expect(staging.reload.position).to eq 1
      expect(closed_list.reload.position).to be_nil
    end
  end

  it 'does not remove list from board when list type is closed' do
    service = described_class.new(parent, user)

    expect { service.execute(closed_list) }.not_to change(board.lists, :count)
  end
end
