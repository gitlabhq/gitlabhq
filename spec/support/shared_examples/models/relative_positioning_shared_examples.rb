# frozen_string_literal: true

# Notes for implementing classes:
#
# The following let bindings should be defined:
# - `factory`: A symbol naming a factory to use to create items
# - `default_params`: A HashMap of factory parameters to pass to the factory.
#
# The `default_params` should include the relative parent, so that any item
# created with these parameters passed to the `factory` will be considered in
# the same set of items relative to each other.
#
# For the purposes of efficiency, it is a good idea to bind the parent in
# `let_it_be`, so that it is re-used across examples, but be careful that it
# does not have any other children - it should only be used within this set of
# shared examples.
RSpec.shared_examples 'a class that supports relative positioning' do
  let(:item1) { create_item }
  let(:item2) { create_item }
  let(:new_item) { create_item(relative_position: nil) }

  let(:set_size) { RelativePositioning.mover.context(item1).scoped_items.count }
  let(:items_with_nil_position_sample_quantity) { 100 }

  def create_item(params = {})
    create(factory, params.merge(default_params))
  end

  def create_items_with_positions(positions)
    positions.map do |position|
      create_item(relative_position: position)
    end
  end

  def as_item(item)
    item # Override to perform a transformation, if necessary
  end

  def as_items(items)
    items.map { |item| as_item(item) }
  end

  describe '#scoped_items' do
    it 'includes all items with the same scope' do
      scope = as_items([item1, item2, new_item, create_item])
      irrelevant = create(factory, {}) # This should not share the scope
      context = RelativePositioning.mover.context(item1)

      same_scope = as_items(context.scoped_items)

      expect(same_scope).to include(*scope)
      expect(same_scope).not_to include(as_item(irrelevant))
    end
  end

  describe '#relative_siblings' do
    it 'includes all items with the same scope, except self' do
      scope = as_items([item2, new_item, create_item])
      irrelevant = create(factory, {}) # This should not share the scope
      context = RelativePositioning.mover.context(item1)

      siblings = as_items(context.relative_siblings)

      expect(siblings).to include(*scope)
      expect(siblings).not_to include(as_item(item1))
      expect(siblings).not_to include(as_item(irrelevant))
    end
  end

  describe '.move_nulls_to_end' do
    let(:item3) { create_item }
    let(:sibling_query) { item1.class.relative_positioning_query_base(item1) }

    it 'moves items with null relative_position to the end' do
      item1.update!(relative_position: 1000)
      item2.update!(relative_position: nil)
      item3.update!(relative_position: nil)

      items = [item1, item2, item3]
      expect(described_class.move_nulls_to_end(items)).to be(2)

      expect(items.sort_by(&:relative_position)).to eq(items)
      expect(item1.relative_position).to be(1000)

      expect(sibling_query.where(relative_position: nil)).not_to exist
      expect(as_items(sibling_query.reorder(:relative_position, :id))).to eq(as_items([item1, item2, item3]))
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

    it 'manages to move nulls to the end even if there is not enough space' do
      run = run_at_end(20).to_a
      bunch_a = create_items_with_positions(run[0..18])
      bunch_b = create_items_with_positions([run.last])

      nils = create_items_with_positions([nil] * 4)
      described_class.move_nulls_to_end(nils)

      items = [*bunch_a, *bunch_b, *nils]
      items.each(&:reset)

      expect(items.map(&:relative_position)).to all(be_valid_position)
      expect(items.reverse.sort_by(&:relative_position)).to eq(items)
    end

    it 'manages to move nulls to the end, stacking if we cannot create enough space' do
      run = run_at_end(40).to_a
      bunch = create_items_with_positions(run.select(&:even?))

      nils = create_items_with_positions([nil] * 20)
      described_class.move_nulls_to_end(nils)

      items = [*bunch, *nils]
      items.each(&:reset)

      expect(items.map(&:relative_position)).to all(be_valid_position)
      expect(bunch.reverse.sort_by(&:relative_position)).to eq(bunch)
      expect(bunch.map(&:relative_position)).to all(be < nils.map(&:relative_position).min)
    end

    it 'manages to move nulls found in the relative scope' do
      nils = create_items_with_positions([nil] * 4)

      described_class.move_nulls_to_end(sibling_query.to_a)
      positions = nils.map { |item| item.reset.relative_position }

      expect(positions).to all(be_present)
      expect(positions).to all(be_valid_position)
    end

    it 'can move many nulls' do
      nils = create_items_with_positions([nil] * items_with_nil_position_sample_quantity)

      described_class.move_nulls_to_end(nils)

      expect(nils.map(&:relative_position)).to all(be_valid_position)
    end

    it 'does not have an N+1 issue' do
      create_items_with_positions(10..12)
      a, b, c, d, e, f, *xs = create_items_with_positions([nil] * 10)

      control = ActiveRecord::QueryRecorder.new do
        described_class.move_nulls_to_end([a, b])
      end

      expect { described_class.move_nulls_to_end([c, d, e, f]) }
        .not_to exceed_query_limit(control)

      expect { described_class.move_nulls_to_end(xs) }
        .not_to exceed_query_limit(control)
    end
  end

  describe '.move_nulls_to_start' do
    let(:item3) { create_item }
    let(:sibling_query) { item1.class.relative_positioning_query_base(item1) }

    it 'moves items with null relative_position to the start' do
      item1.update!(relative_position: nil)
      item2.update!(relative_position: nil)
      item3.update!(relative_position: 1000)

      items = [item1, item2, item3]
      expect(described_class.move_nulls_to_start(items)).to be(2)
      items.map(&:reload)

      expect(items.sort_by(&:relative_position)).to eq(items)
      expect(sibling_query.where(relative_position: nil)).not_to exist
      expect(as_items(sibling_query.reorder(:relative_position, :id))).to eq(as_items(items))
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

    it 'manages to move nulls to the start even if there is not enough space' do
      run = run_at_start(20).to_a
      bunch_a = create_items_with_positions([run.first])
      bunch_b = create_items_with_positions(run[2..])

      nils = create_items_with_positions([nil, nil, nil, nil])
      described_class.move_nulls_to_start(nils)

      items = [*nils, *bunch_a, *bunch_b]
      items.each(&:reset)

      expect(items.map(&:relative_position)).to all(be_valid_position)
      expect(items.reverse.sort_by(&:relative_position)).to eq(items)
    end

    it 'manages to move nulls to the end, stacking if we cannot create enough space' do
      run = run_at_start(40).to_a
      bunch = create_items_with_positions(run.select(&:even?))

      nils = create_items_with_positions([nil].cycle.take(20))
      described_class.move_nulls_to_start(nils)

      items = [*nils, *bunch]
      items.each(&:reset)

      expect(items.map(&:relative_position)).to all(be_valid_position)
      expect(bunch.reverse.sort_by(&:relative_position)).to eq(bunch)
      expect(bunch.map(&:relative_position)).to all(be > nils.map(&:relative_position).max)
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
      let(:item3) { create(factory, default_params) }
      let(:start) { RelativePositioning::START_POSITION }

      before do
        item1.update!(relative_position: start - (RelativePositioning::IDEAL_DISTANCE * 0))
        item2.update!(relative_position: start - (RelativePositioning::IDEAL_DISTANCE * 1))
        item3.update!(relative_position: start - (RelativePositioning::IDEAL_DISTANCE * 2))
      end

      def leap_frog
        a, b = [item1.reset, item2.reset].sort_by(&:relative_position)

        b.move_before(a)
        b.save!
      end

      it 'can leap-frog STEPS times before needing to rebalance' do
        expect { RelativePositioning::STEPS.times { leap_frog } }
          .to change { item3.reload.relative_position }.by(0)
          .and change { item1.reload.relative_position }.by(be < 0)
          .and change { item2.reload.relative_position }.by(be < 0)

        expect { leap_frog }
          .to change { item3.reload.relative_position }.by(be < 0)
      end

      context 'there is no space to the left after moving STEPS times' do
        let(:start) { RelativePositioning::MIN_POSITION + (2 * RelativePositioning::IDEAL_DISTANCE) }

        it 'rebalances to the right' do
          expect { RelativePositioning::STEPS.succ.times { leap_frog } }
            .not_to change { item3.reload.relative_position }
        end
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
        item1.update!(relative_position: start + (RelativePositioning::IDEAL_DISTANCE * 0))
        item2.update!(relative_position: start + (RelativePositioning::IDEAL_DISTANCE * 1))
        item3.update!(relative_position: start + (RelativePositioning::IDEAL_DISTANCE * 2))
      end

      let(:item3) { create(factory, default_params) }

      def leap_frog
        a, b = [item1.reset, item2.reset].sort_by(&:relative_position)

        a.move_after(b)
        a.save!
      end

      it 'rebalances after STEPS jumps' do
        RelativePositioning::STEPS.pred.times do
          expect { leap_frog }
            .to change { item3.reload.relative_position }.by(0)
            .and change { item1.reset.relative_position }.by(be >= 0)
            .and change { item2.reset.relative_position }.by(be >= 0)
        end

        expect { leap_frog }
          .to change { item3.reload.relative_position }.by(0)
          .and change { item1.reset.relative_position }.by(be < 0)
          .and change { item2.reset.relative_position }.by(be < 0)
      end
    end
  end

  describe '#move_to_start' do
    before do
      [item1, item2].each do |item1|
        item1.move_to_start && item1.save!
      end
    end

    it 'places items at most IDEAL_DISTANCE from the start when the range is open' do
      n = set_size

      expect([item1, item2].map(&:relative_position)).to all(be >= (RelativePositioning::START_POSITION - (n * RelativePositioning::IDEAL_DISTANCE)))
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

    it 'places items at most IDEAL_DISTANCE from the start when the range is open' do
      n = set_size

      expect([item1, item2].map(&:relative_position)).to all(be <= (RelativePositioning::START_POSITION + (n * RelativePositioning::IDEAL_DISTANCE)))
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

RSpec.shared_examples 'no-op relative positioning' do
  def create_item(**params)
    create(factory, params.merge(default_params))
  end

  let_it_be(:item1) { create_item }
  let_it_be(:item2) { create_item }
  let_it_be(:new_item) { create_item(relative_position: nil) }

  def any_relative_positions
    new_item.class.reorder(:relative_position, :id).pluck(:id, :relative_position)
  end

  shared_examples 'a no-op method' do
    it 'does not raise errors' do
      expect { perform }.not_to raise_error
    end

    it 'does not perform any DB queries' do
      expect { perform }.not_to exceed_query_limit(0)
    end

    it 'does not change any relative_position' do
      expect { perform }.not_to change { any_relative_positions }
    end
  end

  describe '.scoped_items' do
    subject { RelativePositioning.mover.context(item1).scoped_items }

    it 'is empty' do
      expect(subject).to be_empty
    end
  end

  describe '.relative_siblings' do
    subject { RelativePositioning.mover.context(item1).relative_siblings }

    it 'is empty' do
      expect(subject).to be_empty
    end
  end

  describe '.move_nulls_to_end' do
    subject { item1.class.move_nulls_to_end([new_item, item1]) }

    it_behaves_like 'a no-op method' do
      def perform
        subject
      end
    end

    it 'does not move any items' do
      expect(subject).to eq(0)
    end
  end

  describe '.move_nulls_to_start' do
    subject { item1.class.move_nulls_to_start([new_item, item1]) }

    it_behaves_like 'a no-op method' do
      def perform
        subject
      end
    end

    it 'does not move any items' do
      expect(subject).to eq(0)
    end
  end

  describe 'instance methods' do
    subject { new_item }

    describe '#move_to_start' do
      it_behaves_like 'a no-op method' do
        def perform
          subject.move_to_start
        end
      end
    end

    describe '#move_to_end' do
      it_behaves_like 'a no-op method' do
        def perform
          subject.move_to_end
        end
      end
    end

    describe '#move_between' do
      it_behaves_like 'a no-op method' do
        def perform
          subject.move_between(item1, item2)
        end
      end
    end

    describe '#move_before' do
      it_behaves_like 'a no-op method' do
        def perform
          subject.move_before(item1)
        end
      end
    end

    describe '#move_after' do
      it_behaves_like 'a no-op method' do
        def perform
          subject.move_after(item1)
        end
      end
    end
  end
end
