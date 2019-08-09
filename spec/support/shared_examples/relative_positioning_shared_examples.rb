# frozen_string_literal: true

RSpec.shared_examples 'a class that supports relative positioning' do
  let(:item1) { create(factory, default_params) }
  let(:item2) { create(factory, default_params) }
  let(:new_item) { create(factory, default_params) }

  def create_item(params)
    create(factory, params.merge(default_params))
  end

  def create_items_with_positions(positions)
    positions.map do |position|
      create_item(relative_position: position)
    end
  end

  describe '.move_nulls_to_end' do
    it 'moves items with null relative_position to the end' do
      item1.update!(relative_position: nil)
      item2.update!(relative_position: nil)

      described_class.move_nulls_to_end([item1, item2])

      expect(item2.prev_relative_position).to eq item1.relative_position
      expect(item1.prev_relative_position).to eq nil
      expect(item2.next_relative_position).to eq nil
    end

    it 'moves the item near the start position when there are no existing positions' do
      item1.update!(relative_position: nil)

      described_class.move_nulls_to_end([item1])

      expect(item1.relative_position).to eq(described_class::START_POSITION + described_class::IDEAL_DISTANCE)
    end

    it 'does not perform any moves if all items have their relative_position set' do
      item1.update!(relative_position: 1)

      expect(item1).not_to receive(:save)

      described_class.move_nulls_to_end([item1])
    end
  end

  describe '#max_relative_position' do
    it 'returns maximum position' do
      expect(item1.max_relative_position).to eq item2.relative_position
    end
  end

  describe '#prev_relative_position' do
    it 'returns previous position if there is an item above' do
      item1.update(relative_position: 5)
      item2.update(relative_position: 15)

      expect(item2.prev_relative_position).to eq item1.relative_position
    end

    it 'returns nil if there is no item above' do
      expect(item1.prev_relative_position).to eq nil
    end
  end

  describe '#next_relative_position' do
    it 'returns next position if there is an item below' do
      item1.update(relative_position: 5)
      item2.update(relative_position: 15)

      expect(item1.next_relative_position).to eq item2.relative_position
    end

    it 'returns nil if there is no item below' do
      expect(item2.next_relative_position).to eq nil
    end
  end

  describe '#move_before' do
    it 'moves item before' do
      [item2, item1].each(&:move_to_end)

      item1.move_before(item2)

      expect(item1.relative_position).to be < item2.relative_position
    end
  end

  describe '#move_after' do
    it 'moves item after' do
      [item1, item2].each(&:move_to_end)

      item1.move_after(item2)

      expect(item1.relative_position).to be > item2.relative_position
    end
  end

  describe '#move_to_end' do
    before do
      [item1, item2].each do |item1|
        item1.move_to_end && item1.save
      end
    end

    it 'moves item to the end' do
      new_item.move_to_end

      expect(new_item.relative_position).to be > item2.relative_position
    end
  end

  describe '#move_between' do
    before do
      [item1, item2].each do |item1|
        item1.move_to_end && item1.save
      end
    end

    it 'positions item between two other' do
      new_item.move_between(item1, item2)

      expect(new_item.relative_position).to be > item1.relative_position
      expect(new_item.relative_position).to be < item2.relative_position
    end

    it 'positions item between on top' do
      new_item.move_between(nil, item1)

      expect(new_item.relative_position).to be < item1.relative_position
    end

    it 'positions item between to end' do
      new_item.move_between(item2, nil)

      expect(new_item.relative_position).to be > item2.relative_position
    end

    it 'positions items even when after and before positions are the same' do
      item2.update relative_position: item1.relative_position

      new_item.move_between(item1, item2)

      expect(new_item.relative_position).to be > item1.relative_position
      expect(item1.relative_position).to be < item2.relative_position
    end

    it 'positions items between other two if distance is 1' do
      item2.update relative_position: item1.relative_position + 1

      new_item.move_between(item1, item2)

      expect(new_item.relative_position).to be > item1.relative_position
      expect(item1.relative_position).to be < item2.relative_position
    end

    it 'positions item in the middle of other two if distance is big enough' do
      item1.update relative_position: 6000
      item2.update relative_position: 10000

      new_item.move_between(item1, item2)

      expect(new_item.relative_position).to eq(8000)
    end

    it 'positions item closer to the middle if we are at the very top' do
      item2.update relative_position: 6000

      new_item.move_between(nil, item2)

      expect(new_item.relative_position).to eq(6000 - RelativePositioning::IDEAL_DISTANCE)
    end

    it 'positions item closer to the middle if we are at the very bottom' do
      new_item.update relative_position: 1
      item1.update relative_position: 6000
      item2.destroy

      new_item.move_between(item1, nil)

      expect(new_item.relative_position).to eq(6000 + RelativePositioning::IDEAL_DISTANCE)
    end

    it 'positions item in the middle of other two if distance is not big enough' do
      item1.update relative_position: 100
      item2.update relative_position: 400

      new_item.move_between(item1, item2)

      expect(new_item.relative_position).to eq(250)
    end

    it 'positions item in the middle of other two is there is no place' do
      item1.update relative_position: 100
      item2.update relative_position: 101

      new_item.move_between(item1, item2)

      expect(new_item.relative_position).to be_between(item1.relative_position, item2.relative_position)
    end

    it 'uses rebalancing if there is no place' do
      item1.update relative_position: 100
      item2.update relative_position: 101
      item3 = create_item(relative_position: 102)
      new_item.update relative_position: 103

      new_item.move_between(item2, item3)
      new_item.save!

      expect(new_item.relative_position).to be_between(item2.relative_position, item3.relative_position)
      expect(item1.reload.relative_position).not_to eq(100)
    end

    it 'positions item right if we pass none-sequential parameters' do
      item1.update relative_position: 99
      item2.update relative_position: 101
      item3 = create_item(relative_position: 102)
      new_item.update relative_position: 103

      new_item.move_between(item1, item3)
      new_item.save!

      expect(new_item.relative_position).to be(100)
    end

    it 'avoids N+1 queries when rebalancing other items' do
      items = create_items_with_positions([100, 101, 102])

      count = ActiveRecord::QueryRecorder.new do
        new_item.move_between(items[-2], items[-1])
      end

      items = create_items_with_positions([150, 151, 152, 153, 154])

      expect { new_item.move_between(items[-2], items[-1]) }.not_to exceed_query_limit(count)
    end
  end

  describe '#move_sequence_before' do
    it 'moves the whole sequence of items to the middle of the nearest gap' do
      items = create_items_with_positions([90, 100, 101, 102])

      items.last.move_sequence_before
      items.last.save!

      positions = items.map { |item| item.reload.relative_position }
      expect(positions).to eq([90, 95, 96, 102])
    end

    it 'finds a gap if there are unused positions' do
      items = create_items_with_positions([100, 101, 102])

      items.last.move_sequence_before
      items.last.save!

      positions = items.map { |item| item.reload.relative_position }
      expect(positions).to eq([50, 51, 102])
    end
  end

  describe '#move_sequence_after' do
    it 'moves the whole sequence of items to the middle of the nearest gap' do
      items = create_items_with_positions([100, 101, 102, 110])

      items.first.move_sequence_after
      items.first.save!

      positions = items.map { |item| item.reload.relative_position }
      expect(positions).to eq([100, 105, 106, 110])
    end

    it 'finds a gap if there are unused positions' do
      items = create_items_with_positions([100, 101, 102])

      items.first.move_sequence_after
      items.first.save!

      positions = items.map { |item| item.reload.relative_position }
      expect(positions).to eq([100, 601, 602])
    end
  end
end
