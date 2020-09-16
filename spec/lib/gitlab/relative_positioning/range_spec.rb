# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::RelativePositioning::Range do
  item_a = OpenStruct.new(relative_position: 100, object: :x, positioned?: true)
  item_b = OpenStruct.new(relative_position: 200, object: :y, positioned?: true)

  before do
    allow(item_a).to receive(:lhs_neighbour) { nil }
    allow(item_a).to receive(:rhs_neighbour) { item_b }

    allow(item_b).to receive(:lhs_neighbour) { item_a }
    allow(item_b).to receive(:rhs_neighbour) { nil }
  end

  describe 'RelativePositioning.range' do
    it 'raises if lhs and rhs are nil' do
      expect { Gitlab::RelativePositioning.range(nil, nil) }.to raise_error(ArgumentError)
    end

    it 'raises an error if there is no extent' do
      expect { Gitlab::RelativePositioning.range(item_a, item_a) }.to raise_error(ArgumentError)
    end

    it 'constructs a closed range when both termini are provided' do
      range = Gitlab::RelativePositioning.range(item_a, item_b)
      expect(range).to be_a_kind_of(Gitlab::RelativePositioning::Range)
      expect(range).to be_a_kind_of(Gitlab::RelativePositioning::ClosedRange)
    end

    it 'constructs a starting-from range when only the LHS is provided' do
      range = Gitlab::RelativePositioning.range(item_a, nil)
      expect(range).to be_a_kind_of(Gitlab::RelativePositioning::Range)
      expect(range).to be_a_kind_of(Gitlab::RelativePositioning::StartingFrom)
    end

    it 'constructs an ending-at range when only the RHS is provided' do
      range = Gitlab::RelativePositioning.range(nil, item_b)
      expect(range).to be_a_kind_of(Gitlab::RelativePositioning::Range)
      expect(range).to be_a_kind_of(Gitlab::RelativePositioning::EndingAt)
    end
  end

  it 'infers neighbours correctly' do
    starting_at_a = Gitlab::RelativePositioning.range(item_a, nil)
    ending_at_b = Gitlab::RelativePositioning.range(nil, item_b)

    expect(starting_at_a).to eq(ending_at_b)
  end

  describe '#open_on_left?' do
    where(:lhs, :rhs, :expected_result) do
      [
        [item_a, item_b, false],
        [item_a, nil, false],
        [nil, item_b, false],
        [item_b, nil, false],
        [nil, item_a, true]
      ]
    end

    with_them do
      it 'is true if there is no LHS terminus' do
        range = Gitlab::RelativePositioning.range(lhs, rhs)

        expect(range.open_on_left?).to be(expected_result)
      end
    end
  end

  describe '#open_on_right?' do
    where(:lhs, :rhs, :expected_result) do
      [
        [item_a, item_b, false],
        [item_a, nil, false],
        [nil, item_b, false],
        [item_b, nil, true],
        [nil, item_a, false]
      ]
    end

    with_them do
      it 'is true if there is no RHS terminus' do
        range = Gitlab::RelativePositioning.range(lhs, rhs)

        expect(range.open_on_right?).to be(expected_result)
      end
    end
  end

  describe '#cover?' do
    item_c = OpenStruct.new(relative_position: 150, object: :z, positioned?: true)
    item_d = OpenStruct.new(relative_position: 050, object: :w, positioned?: true)
    item_e = OpenStruct.new(relative_position: 250, object: :r, positioned?: true)
    item_f = OpenStruct.new(positioned?: false)
    item_ax = OpenStruct.new(relative_position: 100, object: :not_x, positioned?: true)
    item_bx = OpenStruct.new(relative_position: 200, object: :not_y, positioned?: true)

    where(:lhs, :rhs, :item, :expected_result) do
      [
        [item_a, item_b, item_a, true],
        [item_a, item_b, item_b, true],
        [item_a, item_b, item_c, true],
        [item_a, item_b, item_d, false],
        [item_a, item_b, item_e, false],
        [item_a, item_b, item_ax, false],
        [item_a, item_b, item_bx, false],
        [item_a, item_b, item_f, false],
        [item_a, item_b, nil, false],

        [nil, item_b, item_a, true],
        [nil, item_b, item_b, true],
        [nil, item_b, item_c, true],
        [nil, item_b, item_d, false],
        [nil, item_b, item_e, false],
        [nil, item_b, item_ax, false],
        [nil, item_b, item_bx, false],
        [nil, item_b, item_f, false],
        [nil, item_b, nil, false],

        [item_a, nil, item_a, true],
        [item_a, nil, item_b, true],
        [item_a, nil, item_c, true],
        [item_a, nil, item_d, false],
        [item_a, nil, item_e, false],
        [item_a, nil, item_ax, false],
        [item_a, nil, item_bx, false],
        [item_a, nil, item_f, false],
        [item_a, nil, nil, false],

        [nil, item_a, item_a, true],
        [nil, item_a, item_b, false],
        [nil, item_a, item_c, false],
        [nil, item_a, item_d, true],
        [nil, item_a, item_e, false],
        [nil, item_a, item_ax, false],
        [nil, item_a, item_bx, false],
        [nil, item_a, item_f, false],
        [nil, item_a, nil, false],

        [item_b, nil, item_a, false],
        [item_b, nil, item_b, true],
        [item_b, nil, item_c, false],
        [item_b, nil, item_d, false],
        [item_b, nil, item_e, true],
        [item_b, nil, item_ax, false],
        [item_b, nil, item_bx, false],
        [item_b, nil, item_f, false],
        [item_b, nil, nil, false]
      ]
    end

    with_them do
      it 'is true when the object is within the bounds of the range' do
        range = Gitlab::RelativePositioning.range(lhs, rhs)

        expect(range.cover?(item)).to be(expected_result)
      end
    end
  end
end
