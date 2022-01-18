# frozen_string_literal: true

RSpec.shared_examples 'destructible' do |factory:|
  let_it_be(:item1) { create(factory, created_at: 1.month.ago, updated_at: 1.day.ago) }
  let_it_be(:item2) { create(factory, created_at: 1.year.ago, updated_at: 1.year.ago) }
  let_it_be(:item3) { create(factory, :pending_destruction, created_at: 2.years.ago, updated_at: 1.month.ago) }
  let_it_be(:item4) { create(factory, :pending_destruction, created_at: 3.years.ago, updated_at: 2.weeks.ago) }

  describe '.next_pending_destruction' do
    it 'returns the oldest item pending destruction based on updated_at' do
      expect(described_class.next_pending_destruction(order_by: :updated_at)).to eq(item3)
    end

    it 'returns the oldest item pending destruction based on created_at' do
      expect(described_class.next_pending_destruction(order_by: :created_at)).to eq(item4)
    end
  end
end
