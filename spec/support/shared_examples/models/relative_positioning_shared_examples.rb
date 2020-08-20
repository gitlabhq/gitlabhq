# frozen_string_literal: true

RSpec.shared_examples 'a class that supports relative positioning' do
  let(:item1) { create_item }
  let(:item2) { create_item }
  let(:new_item) { create_item }

  def create_item(params = {})
    create(factory, params.merge(default_params))
  end

  def create_items_with_positions(positions)
    positions.map do |position|
      create_item(relative_position: position)
    end
  end

  describe '.move_nulls_to_end' do
    let(:item3) { create_item }

    it 'moves items with null relative_position to the end' do
      item1.update!(relative_position: 1000)
      item2.update!(relative_position: nil)
      item3.update!(relative_position: nil)

      items = [item1, item2, item3]
      expect(described_class.move_nulls_to_end(items)).to be(2)

      expect(items.sort_by(&:relative_position)).to eq(items)
      expect(item1.relative_position).to be(1000)
      expect(item1.prev_relative_position).to be_nil
      expect(item1.next_relative_position).to eq(item2.relative_position)
      expect(item2.next_relative_position).to eq(item3.relative_position)
      expect(item3.next_relative_position).to be_nil
    end

    it 'preserves relative position' do
      item1.update!(relative_position: nil)
      item2.update!(relative_position: nil)

      described_class.move_nulls_to_end([item1, item2])

      expect(item1.relative_position).to be < item2.relative_position
    end

    it 'moves the item near the start position when there are no existing positions' do
      item1.update!(relative_position: nil)

      described_class.move_nulls_to_end([item1])
      expect(item1.reset.relative_position).to eq(described_class::START_POSITION + described_class::IDEAL_DISTANCE)
    end

    it 'does not perform any moves if all items have their relative_position set' do
      item1.update!(relative_position: 1)

      expect(described_class.move_nulls_to_start([item1])).to be(0)
      expect(item1.reload.relative_position).to be(1)
    end

    it 'manages to move nulls to the end even if there is a sequence at the end' do
      bunch = create_items_with_positions(run_at_end)
      item1.update!(relative_position: nil)

      described_class.move_nulls_to_end([item1])

      items = [*bunch, item1]
      items.each(&:reset)

      expect(items.map(&:relative_position)).to all(be_valid_position)
      expect(items.sort_by(&:relative_position)).to eq(items)
    end

    it 'does not have an N+1 issue' do
      create_items_with_positions(10..12)

      a, b, c, d, e, f = create_items_with_positions([nil, nil, nil, nil, nil, nil])

      baseline = ActiveRecord::QueryRecorder.new do
        described_class.move_nulls_to_end([a, e])
      end

      expect { described_class.move_nulls_to_end([b, c, d]) }
        .not_to exceed_query_limit(baseline)

      expect { described_class.move_nulls_to_end([f]) }
        .not_to exceed_query_limit(baseline.count)
    end
  end

  describe '.move_nulls_to_start' do
    let(:item3) { create_item }

    it 'moves items with null relative_position to the start' do
      item1.update!(relative_position: nil)
      item2.update!(relative_position: nil)
      item3.update!(relative_position: 1000)

      items = [item1, item2, item3]
      expect(described_class.move_nulls_to_start(items)).to be(2)
      items.map(&:reload)

      expect(items.sort_by(&:relative_position)).to eq(items)
      expect(item1.prev_relative_position).to eq nil
      expect(item1.next_relative_position).to eq item2.relative_position
      expect(item2.next_relative_position).to eq item3.relative_position
      expect(item3.next_relative_position).to eq nil
      expect(item3.relative_position).to be(1000)
    end

    it 'moves the item near the start position when there are no existing positions' do
      item1.update!(relative_position: nil)

      described_class.move_nulls_to_start([item1])

      expect(item1.relative_position).to eq(described_class::START_POSITION - described_class::IDEAL_DISTANCE)
    end

    it 'preserves relative position' do
      item1.update!(relative_position: nil)
      item2.update!(relative_position: nil)

      described_class.move_nulls_to_start([item1, item2])

      expect(item1.relative_position).to be < item2.relative_position
    end

    it 'does not perform any moves if all items have their relative_position set' do
      item1.update!(relative_position: 1)

      expect(described_class.move_nulls_to_start([item1])).to be(0)
      expect(item1.reload.relative_position).to be(1)
    end
  end

  describe '#max_relative_position' do
    it 'returns maximum position' do
      expect(item1.max_relative_position).to eq item2.relative_position
    end
  end

  describe '#prev_relative_position' do
    it 'returns previous position if there is an item above' do
      item1.update!(relative_position: 5)
      item2.update!(relative_position: 15)

      expect(item2.prev_relative_position).to eq item1.relative_position
    end

    it 'returns nil if there is no item above' do
      expect(item1.prev_relative_position).to eq nil
    end
  end

  describe '#next_relative_position' do
    it 'returns next position if there is an item below' do
      item1.update!(relative_position: 5)
      item2.update!(relative_position: 15)

      expect(item1.next_relative_position).to eq item2.relative_position
    end

    it 'returns nil if there is no item below' do
      expect(item2.next_relative_position).to eq nil
    end
  end

  describe '#find_next_gap_before' do
    context 'there is no gap' do
      let(:items) { create_items_with_positions(run_at_start) }

      it 'returns nil' do
        items.each do |item|
          expect(item.send(:find_next_gap_before)).to be_nil
        end
      end
    end

    context 'there is a sequence ending at MAX_POSITION' do
      let(:items) { create_items_with_positions(run_at_end) }

      let(:gaps) do
        items.map { |item| item.send(:find_next_gap_before) }
      end

      it 'can find the gap at the start for any item in the sequence' do
        gap = { start: items.first.relative_position, end: RelativePositioning::MIN_POSITION }

        expect(gaps).to all(eq(gap))
      end

      it 'respects lower bounds' do
        gap = { start: items.first.relative_position, end: 10 }
        new_item.update!(relative_position: 10)

        expect(gaps).to all(eq(gap))
      end
    end

    specify do
      item1.update!(relative_position: 5)

      (0..10).each do |pos|
        item2.update!(relative_position: pos)

        gap = item2.send(:find_next_gap_before)

        expect(gap[:start]).to be <= item2.relative_position
        expect((gap[:end] - gap[:start]).abs).to be >= RelativePositioning::MIN_GAP
        expect(gap[:start]).to be_valid_position
        expect(gap[:end]).to be_valid_position
      end
    end

    it 'deals with there not being any items to the left' do
      create_items_with_positions([1, 2, 3])
      new_item.update!(relative_position: 0)

      expect(new_item.send(:find_next_gap_before)).to eq(start: 0, end: RelativePositioning::MIN_POSITION)
    end

    it 'finds the next gap to the left, skipping adjacent values' do
      create_items_with_positions([1, 9, 10])
      new_item.update!(relative_position: 11)

      expect(new_item.send(:find_next_gap_before)).to eq(start: 9, end: 1)
    end

    it 'finds the next gap to the left' do
      create_items_with_positions([2, 10])

      new_item.update!(relative_position: 15)
      expect(new_item.send(:find_next_gap_before)).to eq(start: 15, end: 10)

      new_item.update!(relative_position: 11)
      expect(new_item.send(:find_next_gap_before)).to eq(start: 10, end: 2)

      new_item.update!(relative_position: 9)
      expect(new_item.send(:find_next_gap_before)).to eq(start: 9, end: 2)

      new_item.update!(relative_position: 5)
      expect(new_item.send(:find_next_gap_before)).to eq(start: 5, end: 2)
    end
  end

  describe '#find_next_gap_after' do
    context 'there is no gap' do
      let(:items) { create_items_with_positions(run_at_end) }

      it 'returns nil' do
        items.each do |item|
          expect(item.send(:find_next_gap_after)).to be_nil
        end
      end
    end

    context 'there is a sequence starting at MIN_POSITION' do
      let(:items) { create_items_with_positions(run_at_start) }

      let(:gaps) do
        items.map { |item| item.send(:find_next_gap_after) }
      end

      it 'can find the gap at the end for any item in the sequence' do
        gap = { start: items.last.relative_position, end: RelativePositioning::MAX_POSITION }

        expect(gaps).to all(eq(gap))
      end

      it 'respects upper bounds' do
        gap = { start: items.last.relative_position, end: 10 }
        new_item.update!(relative_position: 10)

        expect(gaps).to all(eq(gap))
      end
    end

    specify do
      item1.update!(relative_position: 5)

      (0..10).each do |pos|
        item2.update!(relative_position: pos)

        gap = item2.send(:find_next_gap_after)

        expect(gap[:start]).to be >= item2.relative_position
        expect((gap[:end] - gap[:start]).abs).to be >= RelativePositioning::MIN_GAP
        expect(gap[:start]).to be_valid_position
        expect(gap[:end]).to be_valid_position
      end
    end

    it 'deals with there not being any items to the right' do
      create_items_with_positions([1, 2, 3])
      new_item.update!(relative_position: 5)

      expect(new_item.send(:find_next_gap_after)).to eq(start: 5, end: RelativePositioning::MAX_POSITION)
    end

    it 'finds the next gap to the right, skipping adjacent values' do
      create_items_with_positions([1, 2, 10])
      new_item.update!(relative_position: 0)

      expect(new_item.send(:find_next_gap_after)).to eq(start: 2, end: 10)
    end

    it 'finds the next gap to the right' do
      create_items_with_positions([2, 10])

      new_item.update!(relative_position: 0)
      expect(new_item.send(:find_next_gap_after)).to eq(start: 0, end: 2)

      new_item.update!(relative_position: 1)
      expect(new_item.send(:find_next_gap_after)).to eq(start: 2, end: 10)

      new_item.update!(relative_position: 3)
      expect(new_item.send(:find_next_gap_after)).to eq(start: 3, end: 10)

      new_item.update!(relative_position: 5)
      expect(new_item.send(:find_next_gap_after)).to eq(start: 5, end: 10)
    end
  end

  describe '#move_before' do
    let(:item3) { create(factory, default_params) }

    it 'moves item before' do
      [item2, item1].each do |item|
        item.move_to_end
        item.save!
      end

      expect(item1.relative_position).to be > item2.relative_position

      item1.move_before(item2)

      expect(item1.relative_position).to be < item2.relative_position
    end

    context 'when there is no space' do
      before do
        item1.update!(relative_position: 1000)
        item2.update!(relative_position: 1001)
        item3.update!(relative_position: 1002)
      end

      it 'moves items correctly' do
        item3.move_before(item2)

        expect(item3.relative_position).to be_between(item1.reload.relative_position, item2.reload.relative_position).exclusive
      end
    end

    it 'can move the item before an item at the start' do
      item1.update!(relative_position: RelativePositioning::START_POSITION)

      new_item.move_before(item1)

      expect(new_item.relative_position).to be_valid_position
      expect(new_item.relative_position).to be < item1.reload.relative_position
    end

    it 'can move the item before an item at MIN_POSITION' do
      item1.update!(relative_position: RelativePositioning::MIN_POSITION)

      new_item.move_before(item1)

      expect(new_item.relative_position).to be >= RelativePositioning::MIN_POSITION
      expect(new_item.relative_position).to be < item1.reload.relative_position
    end

    it 'can move the item before an item bunched up at MIN_POSITION' do
      item1, item2, item3 = create_items_with_positions(run_at_start)

      new_item.move_before(item3)
      new_item.save!

      items = [item1, item2, new_item, item3]

      items.each do |item|
        expect(item.reset.relative_position).to be_valid_position
      end

      expect(items.sort_by(&:relative_position)).to eq(items)
    end

    context 'leap-frogging to the left' do
      before do
        start = RelativePositioning::START_POSITION
        item1.update!(relative_position: start - RelativePositioning::IDEAL_DISTANCE * 0)
        item2.update!(relative_position: start - RelativePositioning::IDEAL_DISTANCE * 1)
        item3.update!(relative_position: start - RelativePositioning::IDEAL_DISTANCE * 2)
      end

      let(:item3) { create(factory, default_params) }

      def leap_frog(steps)
        a = item1
        b = item2

        steps.times do |i|
          a.move_before(b)
          a.save!
          a, b = b, a
        end
      end

      it 'can leap-frog STEPS - 1 times before needing to rebalance' do
        # This is less efficient than going right, due to the flooring of
        # integer division
        expect { leap_frog(RelativePositioning::STEPS - 1) }
          .not_to change { item3.reload.relative_position }
      end

      it 'rebalances after leap-frogging STEPS times' do
        expect { leap_frog(RelativePositioning::STEPS) }
          .to change { item3.reload.relative_position }
      end
    end
  end

  describe '#move_after' do
    it 'moves item after' do
      [item1, item2].each(&:move_to_end)

      item1.move_after(item2)

      expect(item1.relative_position).to be > item2.relative_position
    end

    context 'when there is no space' do
      let(:item3) { create(factory, default_params) }

      before do
        item1.update!(relative_position: 1000)
        item2.update!(relative_position: 1001)
        item3.update!(relative_position: 1002)
      end

      it 'can move the item after an item at MAX_POSITION' do
        item1.update!(relative_position: RelativePositioning::MAX_POSITION)

        new_item.move_after(item1)
        expect(new_item.relative_position).to be_valid_position
        expect(new_item.relative_position).to be > item1.reset.relative_position
      end

      it 'moves items correctly' do
        item1.move_after(item2)

        expect(item1.relative_position).to be_between(item2.reload.relative_position, item3.reload.relative_position).exclusive
      end
    end

    it 'can move the item after an item bunched up at MAX_POSITION' do
      item1, item2, item3 = create_items_with_positions(run_at_end)

      new_item.move_after(item1)
      new_item.save!

      items = [item1, new_item, item2, item3]

      items.each do |item|
        expect(item.reset.relative_position).to be_valid_position
      end

      expect(items.sort_by(&:relative_position)).to eq(items)
    end

    context 'leap-frogging' do
      before do
        start = RelativePositioning::START_POSITION
        item1.update!(relative_position: start + RelativePositioning::IDEAL_DISTANCE * 0)
        item2.update!(relative_position: start + RelativePositioning::IDEAL_DISTANCE * 1)
        item3.update!(relative_position: start + RelativePositioning::IDEAL_DISTANCE * 2)
      end

      let(:item3) { create(factory, default_params) }

      def leap_frog(steps)
        a = item1
        b = item2

        steps.times do |i|
          a.move_after(b)
          a.save!
          a, b = b, a
        end
      end

      it 'can leap-frog STEPS times before needing to rebalance' do
        expect { leap_frog(RelativePositioning::STEPS) }
          .not_to change { item3.reload.relative_position }
      end

      it 'rebalances after leap-frogging STEPS+1 times' do
        expect { leap_frog(RelativePositioning::STEPS + 1) }
          .to change { item3.reload.relative_position }
      end
    end
  end

  describe '#move_to_start' do
    before do
      [item1, item2].each do |item1|
        item1.move_to_start && item1.save!
      end
    end

    it 'moves item to the end' do
      new_item.move_to_start

      expect(new_item.relative_position).to be < item2.relative_position
    end

    it 'positions the item at MIN_POSITION when there is only one space left' do
      item2.update!(relative_position: RelativePositioning::MIN_POSITION + 1)

      new_item.move_to_start

      expect(new_item.relative_position).to eq RelativePositioning::MIN_POSITION
    end

    it 'rebalances when there is already an item at the MIN_POSITION' do
      item2.update!(relative_position: RelativePositioning::MIN_POSITION)

      new_item.move_to_start
      item2.reset

      expect(new_item.relative_position).to be < item2.relative_position
      expect(new_item.relative_position).to be >= RelativePositioning::MIN_POSITION
    end

    it 'deals with a run of elements at the start' do
      item1.update!(relative_position: RelativePositioning::MIN_POSITION + 1)
      item2.update!(relative_position: RelativePositioning::MIN_POSITION)

      new_item.move_to_start
      item1.reset
      item2.reset

      expect(item2.relative_position).to be < item1.relative_position
      expect(new_item.relative_position).to be < item2.relative_position
      expect(new_item.relative_position).to be >= RelativePositioning::MIN_POSITION
    end
  end

  describe '#move_to_end' do
    before do
      [item1, item2].each do |item1|
        item1.move_to_end && item1.save!
      end
    end

    it 'moves item to the end' do
      new_item.move_to_end

      expect(new_item.relative_position).to be > item2.relative_position
    end

    it 'positions the item at MAX_POSITION when there is only one space left' do
      item2.update!(relative_position: RelativePositioning::MAX_POSITION - 1)

      new_item.move_to_end

      expect(new_item.relative_position).to eq RelativePositioning::MAX_POSITION
    end

    it 'rebalances when there is already an item at the MAX_POSITION' do
      item2.update!(relative_position: RelativePositioning::MAX_POSITION)

      new_item.move_to_end
      item2.reset

      expect(new_item.relative_position).to be > item2.relative_position
      expect(new_item.relative_position).to be <= RelativePositioning::MAX_POSITION
    end

    it 'deals with a run of elements at the end' do
      item1.update!(relative_position: RelativePositioning::MAX_POSITION - 1)
      item2.update!(relative_position: RelativePositioning::MAX_POSITION)

      new_item.move_to_end
      item1.reset
      item2.reset

      expect(item2.relative_position).to be > item1.relative_position
      expect(new_item.relative_position).to be > item2.relative_position
      expect(new_item.relative_position).to be <= RelativePositioning::MAX_POSITION
    end
  end

  describe '#move_between' do
    before do
      [item1, item2].each do |item|
        item.move_to_end && item.save!
      end
    end

    shared_examples 'moves item between' do
      it 'moves the middle item to between left and right' do
        expect do
          middle.move_between(left, right)
          middle.save!
        end.to change { between_exclusive?(left, middle, right) }.from(false).to(true)
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
      item2.update! relative_position: item1.relative_position

      new_item.move_between(item1, item2)
      [item1, item2].each(&:reset)

      expect(new_item.relative_position).to be > item1.relative_position
      expect(item1.relative_position).to be < item2.relative_position
    end

    context 'the two items are next to each other' do
      let(:left) { item1 }
      let(:middle) { new_item }
      let(:right) { create_item(relative_position: item1.relative_position + 1) }

      it_behaves_like 'moves item between'
    end

    it 'positions item in the middle of other two if distance is big enough' do
      item1.update! relative_position: 6000
      item2.update! relative_position: 10000

      new_item.move_between(item1, item2)

      expect(new_item.relative_position).to eq(8000)
    end

    it 'positions item closer to the middle if we are at the very top' do
      item1.update!(relative_position: 6001)
      item2.update!(relative_position: 6000)

      new_item.move_between(nil, item2)

      expect(new_item.relative_position).to eq(6000 - RelativePositioning::IDEAL_DISTANCE)
    end

    it 'positions item closer to the middle if we are at the very bottom' do
      new_item.update!(relative_position: 1)
      item1.update!(relative_position: 6000)
      item2.update!(relative_position: 5999)

      new_item.move_between(item1, nil)

      expect(new_item.relative_position).to eq(6000 + RelativePositioning::IDEAL_DISTANCE)
    end

    it 'positions item in the middle of other two' do
      item1.update! relative_position: 100
      item2.update! relative_position: 400

      new_item.move_between(item1, item2)

      expect(new_item.relative_position).to eq(250)
    end

    context 'there is no space' do
      let(:middle) { new_item }
      let(:left) { create_item(relative_position: 100) }
      let(:right) { create_item(relative_position: 101) }

      it_behaves_like 'moves item between'
    end

    context 'there is a bunch of items' do
      let(:items) { create_items_with_positions(100..104) }
      let(:left) { items[1] }
      let(:middle) { items[3] }
      let(:right) { items[2] }

      it_behaves_like 'moves item between'

      it 'handles bunches correctly' do
        middle.move_between(left, right)
        middle.save!

        expect(items.first.reset.relative_position).to be < middle.relative_position
      end
    end

    it 'positions item right if we pass non-sequential parameters' do
      item1.update! relative_position: 99
      item2.update! relative_position: 101
      item3 = create_item(relative_position: 102)
      new_item.update! relative_position: 103

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

    it 'raises an error if there is no space' do
      items = create_items_with_positions(run_at_start)

      expect { items.last.move_sequence_before }.to raise_error(RelativePositioning::NoSpaceLeft)
    end

    it 'finds a gap if there are unused positions' do
      items = create_items_with_positions([100, 101, 102])

      items.last.move_sequence_before
      items.last.save!

      positions = items.map { |item| item.reload.relative_position }

      expect(positions.last - positions.second).to be > RelativePositioning::MIN_GAP
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
      expect(positions.second - positions.first).to be > RelativePositioning::MIN_GAP
    end

    it 'raises an error if there is no space' do
      items = create_items_with_positions(run_at_end)

      expect { items.first.move_sequence_after }.to raise_error(RelativePositioning::NoSpaceLeft)
    end
  end

  def be_valid_position
    be_between(RelativePositioning::MIN_POSITION, RelativePositioning::MAX_POSITION)
  end

  def between_exclusive?(left, middle, right)
    a, b, c = [left, middle, right].map { |item| item.reset.relative_position }
    return false if a.nil? || b.nil?
    return a < b if c.nil?

    a < b && b < c
  end

  def run_at_end(size = 3)
    (RelativePositioning::MAX_POSITION - size)..RelativePositioning::MAX_POSITION
  end

  def run_at_start(size = 3)
    (RelativePositioning::MIN_POSITION..).take(size)
  end
end
