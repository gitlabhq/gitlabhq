# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::RelativePositioning::ItemContext do
  let_it_be(:default_user) { create_default(:user) }
  let_it_be(:project, reload: true) { create(:project) }

  def create_issue(pos)
    create(:issue, project: project, relative_position: pos)
  end

  range = (101..107) # A deliberately small range, so we can test everything
  indices = (0..).take(range.size)

  let(:start) { ((range.first + range.last) / 2.0).floor }
  let(:subjects) { issues.map { |i| described_class.new(i.reset, range) } }

  # This allows us to refer to range in methods and examples
  let_it_be(:full_range) { range }

  context 'there are gaps at the start and end' do
    let_it_be(:issues) { (range.first.succ..range.last.pred).map { |pos| create_issue(pos) } }

    it 'is always possible to find a gap' do
      expect(subjects)
        .to all(have_attributes(find_next_gap_before: be_present, find_next_gap_after: be_present))
    end

    where(:index) { indices.reverse.drop(2) }

    with_them do
      subject { subjects[index] }

      let(:positions) { subject.scoped_items.map(&:relative_position) }

      it 'is possible to shift_right, which will consume the gap at the end' do
        subject.shift_right

        expect(subject.find_next_gap_after).not_to be_present

        expect(positions).to all(be_between(range.first, range.last))
        expect(positions).to eq(positions.uniq)
      end

      it 'is possible to create_space_right, which will move the gap to immediately after' do
        subject.create_space_right

        expect(subject.find_next_gap_after).to have_attributes(start_pos: subject.relative_position)
        expect(positions).to all(be_between(range.first, range.last))
        expect(positions).to eq(positions.uniq)
      end

      it 'is possible to shift_left, which will consume the gap at the start' do
        subject.shift_left

        expect(subject.find_next_gap_before).not_to be_present
        expect(positions).to all(be_between(range.first, range.last))
        expect(positions).to eq(positions.uniq)
      end

      it 'is possible to create_space_left, which will move the gap to immediately before' do
        subject.create_space_left

        expect(subject.find_next_gap_before).to have_attributes(start_pos: subject.relative_position)
        expect(positions).to all(be_between(range.first, range.last))
        expect(positions).to eq(positions.uniq)
      end
    end
  end

  context 'there is a gap of multiple spaces' do
    let_it_be(:issues) { [range.first, range.last].map { |pos| create_issue(pos) } }

    it 'is impossible to move the last element to the right' do
      expect { subjects.last.shift_right }.to raise_error(Gitlab::RelativePositioning::NoSpaceLeft)
    end

    it 'is impossible to move the first element to the left' do
      expect { subjects.first.shift_left }.to raise_error(Gitlab::RelativePositioning::NoSpaceLeft)
    end

    it 'is possible to move the last element to the left' do
      subject = subjects.last

      expect { subject.shift_left }.to change { subject.relative_position }.by(be < 0)
    end

    it 'is possible to move the first element to the right' do
      subject = subjects.first

      expect { subject.shift_right }.to change { subject.relative_position }.by(be > 0)
    end

    it 'is possible to find the gap from the right' do
      gap = Gitlab::RelativePositioning::Gap.new(range.last, range.first)

      expect(subjects.last).to have_attributes(
        find_next_gap_before: eq(gap),
        find_next_gap_after: be_nil
      )
    end

    it 'is possible to find the gap from the left' do
      gap = Gitlab::RelativePositioning::Gap.new(range.first, range.last)

      expect(subjects.first).to have_attributes(
        find_next_gap_before: be_nil,
        find_next_gap_after: eq(gap)
      )
    end
  end

  context 'there are several free spaces' do
    let_it_be(:issues) { range.select(&:even?).map { |pos| create_issue(pos) } }
    let_it_be(:gaps) do
      range.select(&:odd?).map do |pos|
        rhs = pos.succ.clamp(range.first, range.last)
        lhs = pos.pred.clamp(range.first, range.last)

        {
          before: Gitlab::RelativePositioning::Gap.new(rhs, lhs),
          after: Gitlab::RelativePositioning::Gap.new(lhs, rhs)
        }
      end
    end

    def issue_at(position)
      issues.find { |i| i.relative_position == position }
    end

    where(:current_pos) { range.select(&:even?) }

    with_them do
      let(:subject) { subjects.find { |s| s.relative_position == current_pos } }
      let(:siblings) { subjects.reject { |s| s.relative_position == current_pos } }

      def covered_by_range(pos)
        full_range.cover?(pos) ? pos : nil
      end

      it 'finds the closest gap' do
        closest_gap_before = gaps
          .map { |gap| gap[:before] }
          .select { |gap| gap.start_pos <= subject.relative_position }
          .max_by { |gap| gap.start_pos }
        closest_gap_after = gaps
          .map { |gap| gap[:after] }
          .select { |gap| gap.start_pos >= subject.relative_position }
          .min_by { |gap| gap.start_pos }

        expect(subject).to have_attributes(
          find_next_gap_before: closest_gap_before,
          find_next_gap_after: closest_gap_after
        )
      end

      it 'finds the neighbours' do
        expect(subject).to have_attributes(
          lhs_neighbour: subject.neighbour(issue_at(subject.relative_position - 2)),
          rhs_neighbour: subject.neighbour(issue_at(subject.relative_position + 2))
        )
      end

      it 'finds the next relative_positions' do
        expect(subject).to have_attributes(
          prev_relative_position: covered_by_range(subject.relative_position - 2),
          next_relative_position: covered_by_range(subject.relative_position + 2)
        )
      end

      it 'finds the min/max positions' do
        expect(subject).to have_attributes(
          min_relative_position: issues.first.relative_position,
          max_relative_position: issues.last.relative_position
        )
      end

      it 'finds the min/max siblings' do
        expect(subject).to have_attributes(
          min_sibling: siblings.first,
          max_sibling: siblings.last
        )
      end
    end
  end

  context 'there is at least one free space' do
    where(:free_space) { range.to_a }

    with_them do
      let(:issues) { range.reject { |x| x == free_space }.map { |p| create_issue(p) } }
      let(:gap_rhs) { free_space.succ.clamp(range.first, range.last) }
      let(:gap_lhs) { free_space.pred.clamp(range.first, range.last) }

      it 'can always find a gap before if there is space to the left' do
        expected_gap = Gitlab::RelativePositioning::Gap.new(gap_rhs, gap_lhs)

        to_the_right_of_gap = subjects.select { |s| free_space < s.relative_position }

        expect(to_the_right_of_gap)
          .to all(have_attributes(find_next_gap_before: eq(expected_gap), find_next_gap_after: be_nil))
      end

      it 'can always find a gap after if there is space to the right' do
        expected_gap = Gitlab::RelativePositioning::Gap.new(gap_lhs, gap_rhs)

        to_the_left_of_gap = subjects.select { |s| s.relative_position < free_space }

        expect(to_the_left_of_gap)
          .to all(have_attributes(find_next_gap_before: be_nil, find_next_gap_after: eq(expected_gap)))
      end
    end
  end

  describe '#at_position' do
    let_it_be(:issue) { create_issue(500) }
    let_it_be(:issue_2) { create_issue(510) }

    let(:subject) { described_class.new(issue, range) }

    it 'finds the item at the specified position' do
      expect(subject.at_position(500)).to eq(described_class.new(issue, range))
      expect(subject.at_position(510)).to eq(described_class.new(issue_2, range))
    end

    it 'raises InvalidPosition when the item cannot be found' do
      expect { subject.at_position(501) }.to raise_error Gitlab::RelativePositioning::InvalidPosition
    end
  end
end
