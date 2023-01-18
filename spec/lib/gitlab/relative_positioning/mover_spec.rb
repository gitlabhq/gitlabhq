# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RelativePositioning::Mover, feature_category: :portfolio_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:one_sibling, reload: true) { create(:project, creator: user, namespace: user.namespace) }
  let_it_be(:one_free_space, reload: true) { create(:project, creator: user, namespace: user.namespace) }
  let_it_be(:fully_occupied, reload: true) { create(:project, creator: user, namespace: user.namespace) }
  let_it_be(:no_issues, reload: true) { create(:project, creator: user, namespace: user.namespace) }
  let_it_be(:three_sibs, reload: true) { create(:project, creator: user, namespace: user.namespace) }

  def create_issue(pos, parent = project)
    create(:issue, author: user, project: parent, relative_position: pos)
  end

  range = (101..105)
  indices = (0..).take(range.size)

  let(:start) { ((range.first + range.last) / 2.0).floor }

  subject { described_class.new(start, range) }

  let_it_be(:full_set) do
    range.each_with_index.map do |pos, i|
      create(:issue, iid: i.succ, project: fully_occupied, relative_position: pos)
    end
  end

  let_it_be(:sole_sibling) { create(:issue, iid: 1, project: one_sibling, relative_position: nil) }
  let_it_be(:one_sibling_set) { [sole_sibling] }
  let_it_be(:one_free_space_set) do
    indices.drop(1).map { |iid| create(:issue, project: one_free_space, iid: iid.succ) }
  end

  let_it_be(:three_sibs_set) do
    [1, 2, 3].map { |iid| create(:issue, iid: iid, project: three_sibs) }
  end

  def set_positions(positions)
    mapping = issues.zip(positions).to_h do |issue, pos|
      [issue, { relative_position: pos }]
    end

    ::Gitlab::Database::BulkUpdate.execute([:relative_position], mapping)
  end

  def ids_in_position_order
    project.issues.reorder(:relative_position).pluck(:id)
  end

  def relative_positions
    project.issues.pluck(:relative_position)
  end

  describe '#move_to_end' do
    def max_position
      project.issues.maximum(:relative_position)
    end

    def move_to_end(issue)
      subject.move_to_end(issue)
      issue.save!
    end

    shared_examples 'able to place a new item at the end' do
      it 'can place any new item' do
        existing_issues = ids_in_position_order
        new_item = create_issue(nil)

        expect do
          move_to_end(new_item)
        end.to change { project.issues.pluck(:id, :relative_position) }

        expect(new_item.relative_position).to eq(max_position)
        expect(relative_positions).to all(be_between(range.first, range.last))
        expect(ids_in_position_order).to eq(existing_issues + [new_item.id])
      end
    end

    shared_examples 'able to move existing items to the end' do
      it 'can move any existing item' do
        issues = project.issues.reorder(:relative_position).to_a
        issue = issues[index]
        other_issues = issues.reject { |i| i == issue }
        expect(relative_positions).to all(be_between(range.first, range.last))

        if issues.last == issue
          move_to_end(issue) # May not change the positions
        else
          expect do
            move_to_end(issue)
          end.to change { project.issues.pluck(:id, :relative_position) }
        end

        project.reset

        expect(relative_positions).to all(be_between(range.first, range.last))
        expect(issue.relative_position).to eq(max_position)
        expect(ids_in_position_order).to eq(other_issues.map(&:id) + [issue.id])
      end
    end

    context 'all positions are taken' do
      let(:issues) { full_set }
      let(:project) { fully_occupied }

      it 'raises an error when placing a new item' do
        new_item = create_issue(nil)

        expect { subject.move_to_end(new_item) }.to raise_error(RelativePositioning::NoSpaceLeft)
      end

      where(:index) { indices }

      with_them do
        it_behaves_like 'able to move existing items to the end'
      end
    end

    context 'there are no siblings' do
      let(:issues) { [] }
      let(:project) { no_issues }

      it_behaves_like 'able to place a new item at the end'
    end

    context 'there is only one sibling' do
      where(:pos) { range.to_a }

      with_them do
        let(:issues) { one_sibling_set }
        let(:project) { one_sibling }
        let(:index) { 0 }

        before do
          sole_sibling.reset.update!(relative_position: pos)
        end

        it_behaves_like 'able to place a new item at the end'

        it_behaves_like 'able to move existing items to the end'
      end
    end

    context 'at least one position is free' do
      where(:free_space, :index) do
        is = indices.take(range.size - 1)

        range.to_a.product(is)
      end

      with_them do
        let(:issues) { one_free_space_set }
        let(:project) { one_free_space }

        before do
          positions = range.reject { |x| x == free_space }
          set_positions(positions)
        end

        it_behaves_like 'able to place a new item at the end'

        it_behaves_like 'able to move existing items to the end'
      end
    end
  end

  describe '#move_to_start' do
    def min_position
      project.issues.minimum(:relative_position)
    end

    def move_to_start(issue)
      subject.move_to_start(issue)
      issue.save!
    end

    shared_examples 'able to place a new item at the start' do
      it 'can place any new item' do
        existing_issues = ids_in_position_order
        new_item = create_issue(nil)

        expect do
          move_to_start(new_item)
        end.to change { project.issues.pluck(:id, :relative_position) }

        expect(relative_positions).to all(be_between(range.first, range.last))
        expect(new_item.relative_position).to eq(min_position)
        expect(ids_in_position_order).to eq([new_item.id] + existing_issues)
      end
    end

    shared_examples 'able to move existing items to the start' do
      it 'can move any existing item' do
        issues = project.issues.reorder(:relative_position).to_a
        issue = issues[index]
        other_issues = issues.reject { |i| i == issue }
        expect(relative_positions).to all(be_between(range.first, range.last))

        if issues.first == issue
          move_to_start(issue) # May not change the positions
        else
          expect do
            move_to_start(issue)
          end.to change { project.issues.pluck(:id, :relative_position) }
        end

        project.reset

        expect(relative_positions).to all(be_between(range.first, range.last))
        expect(issue.relative_position).to eq(min_position)
        expect(ids_in_position_order).to eq([issue.id] + other_issues.map(&:id))
      end
    end

    context 'all positions are taken' do
      let(:issues) { full_set }
      let(:project) { fully_occupied }

      it 'raises an error when placing a new item' do
        new_item = create(:issue, project: project, relative_position: nil)

        expect { subject.move_to_start(new_item) }.to raise_error(RelativePositioning::NoSpaceLeft)
      end

      where(:index) { indices }

      with_them do
        it_behaves_like 'able to move existing items to the start'
      end
    end

    context 'there are no siblings' do
      let(:project) { no_issues }
      let(:issues) { [] }

      it_behaves_like 'able to place a new item at the start'
    end

    context 'there is only one sibling' do
      where(:pos) { range.to_a }

      with_them do
        let(:issues) { one_sibling_set }
        let(:project) { one_sibling }
        let(:index) { 0 }

        before do
          sole_sibling.reset.update!(relative_position: pos)
        end

        it_behaves_like 'able to place a new item at the start'

        it_behaves_like 'able to move existing items to the start'
      end
    end

    context 'at least one position is free' do
      where(:free_space, :index) do
        range.to_a.product((0..).take(range.size - 1).to_a)
      end

      with_them do
        let(:issues) { one_free_space_set }
        let(:project) { one_free_space }

        before do
          set_positions(range.reject { |x| x == free_space })
        end

        it_behaves_like 'able to place a new item at the start'

        it_behaves_like 'able to move existing items to the start'
      end
    end
  end

  describe '#move' do
    shared_examples 'able to move a new item' do
      let(:other_issues) { project.issues.reorder(relative_position: :asc).to_a }
      let!(:previous_order) { other_issues.map(&:id) }

      it 'can place any new item betwen two others' do
        new_item = create_issue(nil)

        subject.move(new_item, lhs, rhs)
        new_item.save!
        lhs.reset
        rhs.reset

        expect(new_item.relative_position).to be_between(range.first, range.last)
        expect(new_item.relative_position).to be_between(lhs.relative_position, rhs.relative_position)

        ids = project.issues.reorder(:relative_position).pluck(:id).reject { |id| id == new_item.id }
        expect(ids).to eq(previous_order)
      end

      it 'can place any new item after another' do
        new_item = create_issue(nil)

        subject.move(new_item, lhs, nil)
        new_item.save!
        lhs.reset

        expect(new_item.relative_position).to be_between(range.first, range.last)
        expect(new_item.relative_position).to be > lhs.relative_position

        ids = project.issues.reorder(:relative_position).pluck(:id).reject { |id| id == new_item.id }
        expect(ids).to eq(previous_order)
      end

      it 'can place any new item before another' do
        new_item = create_issue(nil)

        subject.move(new_item, nil, rhs)
        new_item.save!
        rhs.reset

        expect(new_item.relative_position).to be_between(range.first, range.last)
        expect(new_item.relative_position).to be < rhs.relative_position

        ids = project.issues.reorder(:relative_position).pluck(:id).reject { |id| id == new_item.id }
        expect(ids).to eq(previous_order)
      end
    end

    shared_examples 'able to move an existing item' do
      let(:all_issues) { project.issues.reorder(:relative_position).to_a }
      let(:item) { all_issues[index] }
      let(:positions) { project.reset.issues.pluck(:relative_position) }
      let(:other_issues) { all_issues.reject { |i| i == item } }
      let!(:previous_order) { other_issues.map(&:id) }
      let(:new_order) do
        project.issues.where.not(id: item.id).reorder(:relative_position).pluck(:id)
      end

      it 'can place any item betwen two others' do
        subject.move(item, lhs, rhs)
        item.save!
        lhs.reset
        rhs.reset

        expect(positions).to all(be_between(range.first, range.last))
        expect(positions).to match_array(positions.uniq)
        expect(item.relative_position).to be_between(lhs.relative_position, rhs.relative_position)

        expect(new_order).to eq(previous_order)
      end

      def sequence(expected_sequence)
        range = (expected_sequence.first.relative_position..expected_sequence.last.relative_position)

        project.issues.reorder(:relative_position).where(relative_position: range)
      end

      it 'can place any item after another' do
        subject.move(item, lhs, nil)
        item.save!
        lhs.reset

        expect(positions).to all(be_between(range.first, range.last))
        expect(positions).to match_array(positions.uniq)
        expect(item.relative_position).to be >= lhs.relative_position

        expected_sequence = [lhs, item].uniq

        expect(sequence(expected_sequence)).to eq(expected_sequence)

        expect(new_order).to eq(previous_order)
      end

      it 'can place any item before another' do
        subject.move(item, nil, rhs)
        item.save!
        rhs.reset

        expect(positions).to all(be_between(range.first, range.last))
        expect(positions).to match_array(positions.uniq)
        expect(item.relative_position).to be <= rhs.relative_position

        expected_sequence = [item, rhs].uniq

        expect(sequence(expected_sequence)).to eq(expected_sequence)

        expect(new_order).to eq(previous_order)
      end
    end

    context 'all positions are taken' do
      let(:issues) { full_set }
      let(:project) { fully_occupied }

      where(:idx_a, :idx_b) do
        indices.product(indices).select { |a, b| a < b }
      end

      with_them do
        let(:lhs) { issues[idx_a].reset }
        let(:rhs) { issues[idx_b].reset }

        it 'raises an error when placing a new item anywhere' do
          new_item = create_issue(nil)

          expect { subject.move(new_item, lhs, rhs) }
            .to raise_error(Gitlab::RelativePositioning::NoSpaceLeft)

          expect { subject.move(new_item, nil, rhs) }
            .to raise_error(Gitlab::RelativePositioning::NoSpaceLeft)

          expect { subject.move(new_item, lhs, nil) }
            .to raise_error(Gitlab::RelativePositioning::NoSpaceLeft)
        end

        where(:index) { indices }

        with_them do
          it_behaves_like 'able to move an existing item'
        end
      end
    end

    context 'there are no siblings' do
      let(:project) { no_issues }

      it 'raises an ArgumentError when both first and last are nil' do
        new_item = create_issue(nil)

        expect { subject.move(new_item, nil, nil) }.to raise_error(ArgumentError)
      end
    end

    context 'there are a couple of siblings' do
      where(:pos_movable, :pos_a, :pos_b) do
        xs = range.to_a

        xs.product(xs).product(xs).map(&:flatten)
          .select { |vals| vals == vals.uniq && vals[1] < vals[2] }
      end

      with_them do
        let(:issues) { three_sibs_set }
        let(:project) { three_sibs }
        let(:index) { 0 }
        let(:lhs) { issues[1] }
        let(:rhs) { issues[2] }

        before do
          set_positions([pos_movable, pos_a, pos_b])
        end

        it_behaves_like 'able to move a new item'
        it_behaves_like 'able to move an existing item'
      end
    end

    context 'at least one position is free' do
      where(:free_space, :index, :pos_a, :pos_b) do
        is = indices.reverse.drop(1)

        range.to_a.product(is).product(is).product(is)
          .map(&:flatten)
          .select { |_, _, a, b| a < b }
      end

      with_them do
        let(:issues) { one_free_space_set }
        let(:project) { one_free_space }
        let(:lhs) { issues[pos_a] }
        let(:rhs) { issues[pos_b] }

        before do
          set_positions(range.reject { |x| x == free_space })
        end

        it_behaves_like 'able to move a new item'
        it_behaves_like 'able to move an existing item'
      end
    end
  end
end
