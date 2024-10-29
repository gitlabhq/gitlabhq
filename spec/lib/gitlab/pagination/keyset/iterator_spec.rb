# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Pagination::Keyset::Iterator do
  let_it_be(:project) { create(:project) }
  let_it_be(:issue_list_with_same_pos) { create_list(:issue, 3, project: project, relative_position: 100, updated_at: 1.day.ago) }
  let_it_be(:issue_list_with_null_pos) { create_list(:issue, 3, project: project, relative_position: nil, updated_at: 1.day.ago) }
  let_it_be(:issue_list_with_asc_pos) { create_list(:issue, 3, :with_asc_relative_position, project: project, updated_at: 1.day.ago) }

  let(:klass) { Issue }
  let(:column) { 'relative_position' }
  let(:direction) { :asc }
  let(:reverse_direction) { ::Gitlab::Pagination::Keyset::ColumnOrderDefinition::REVERSED_ORDER_DIRECTIONS[direction] }
  let(:nulls_position) { :nulls_last }
  let(:reverse_nulls_position) { ::Gitlab::Pagination::Keyset::ColumnOrderDefinition::REVERSED_NULL_POSITIONS[nulls_position] }
  let(:custom_reorder) do
    Gitlab::Pagination::Keyset::Order.build(
      [
        Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
          attribute_name: column,
          column_expression: klass.arel_table[column],
          order_expression: klass.arel_table[column].public_send(direction).public_send(nulls_position),
          reversed_order_expression: klass.arel_table[column].public_send(reverse_direction).public_send(reverse_nulls_position),
          order_direction: direction,
          nullable: nulls_position
        ),
        Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
          attribute_name: 'id',
          order_expression: klass.arel_table[:id].send(direction)
        )
      ])
  end

  let(:iterator_params) { nil }
  let(:scope) { project.issues.reorder(custom_reorder) }

  subject(:iterator) { described_class.new(**iterator_params) }

  shared_examples 'iterator examples' do
    describe '.each_batch' do
      it 'yields an ActiveRecord::Relation when a block is given' do
        iterator.each_batch(of: 1) do |relation|
          expect(relation).to be_a_kind_of(ActiveRecord::Relation)
        end
      end

      it 'accepts a custom batch size' do
        count = 0

        iterator.each_batch(of: 2) { |relation| count += relation.count(:all) }

        expect(count).to eq(9)
      end

      it 'does not yield an empty relation' do
        iteration_count = 0

        iterator.each_batch(of: 1) { iteration_count += 1 }

        expect(iteration_count).to eq(9)
      end

      it 'loads the batch relation' do
        loaded = false

        iterator.each_batch { |batch| loaded = batch.loaded? }

        expect(loaded).to be(true)
      end

      it 'continues after the cursor' do
        loaded_records = []
        cursor = nil

        # stopping the iterator after the first batch and storing the cursor
        iterator.each_batch(of: 2) do |relation| # rubocop: disable Lint/UnreachableLoop
          loaded_records.concat(relation.to_a)
          record = loaded_records.last

          cursor = custom_reorder.cursor_attributes_for_node(record)
          break
        end

        expect(loaded_records).to eq(project.issues.order(custom_reorder).take(2))

        new_iterator = described_class.new(**iterator_params.merge(cursor: cursor))
        new_iterator.each_batch(of: 2) do |relation|
          loaded_records.concat(relation.to_a)
        end

        expect(loaded_records).to eq(project.issues.order(custom_reorder))
      end

      it 'allows updating of the yielded relations' do
        time = Time.current

        iterator.each_batch(of: 2) do |relation|
          Issue.connection.execute("UPDATE issues SET updated_at = '#{time.to_fs(:inspect)}' WHERE id IN (#{relation.reselect(:id).to_sql})")
        end

        expect(Issue.pluck(:updated_at)).to all(be_within(5.seconds).of(time))
      end

      context 'with ordering direction' do
        context 'when ordering asc' do
          it 'orders ascending by default, including secondary order column' do
            positions = []

            iterator.each_batch(of: 2) { |rel| positions.concat(rel.pluck(:relative_position, :id)) }

            expect(positions).to eq(project.issues.reorder(Issue.arel_table[:relative_position].asc.nulls_last).order(id: :asc).pluck(:relative_position, :id))
          end
        end

        context 'when reversing asc order' do
          let(:scope) { project.issues.order(custom_reorder.reversed_order) }

          it 'orders in reverse of ascending' do
            positions = []

            iterator.each_batch(of: 2) { |rel| positions.concat(rel.pluck(:relative_position, :id)) }

            expect(positions).to eq(project.issues.reorder(Issue.arel_table[:relative_position].desc.nulls_first).order(id: :desc).pluck(:relative_position, :id))
          end
        end

        context 'when asc order, with nulls first' do
          let(:nulls_position) { :nulls_first }

          it 'orders ascending with nulls first' do
            positions = []

            iterator.each_batch(of: 2) { |rel| positions.concat(rel.pluck(:relative_position, :id)) }

            expect(positions).to eq(project.issues.reorder(Issue.arel_table[:relative_position].asc.nulls_first).order(id: :asc).pluck(:relative_position, :id))
          end
        end

        context 'when ordering desc' do
          let(:direction) { :desc }
          let(:nulls_position) { :nulls_last }

          it 'orders descending' do
            positions = []

            iterator.each_batch(of: 2) { |rel| positions.concat(rel.pluck(:relative_position, :id)) }

            expect(positions).to eq(project.issues.reorder(Issue.arel_table[:relative_position].desc.nulls_last).order(id: :desc).pluck(:relative_position, :id))
          end
        end

        context 'when ordering by columns are repeated twice' do
          let(:direction) { :desc }
          let(:column) { :id }

          it 'orders descending' do
            positions = []

            iterator.each_batch(of: 2) { |rel| positions.concat(rel.pluck(:id)) }

            expect(positions).to eq(project.issues.reorder(id: :desc).pluck(:id))
          end
        end
      end

      context 'when the `load_batch` kwarg is set as `false`' do
        it 'does not load the batch relation' do
          loaded = true

          iterator.each_batch(load_batch: false) { |batch| loaded = batch.loaded? }

          expect(loaded).to be_nil
        end

        it 'does not yield an empty relation' do
          iteration_count = 0

          iterator.each_batch(of: 1, load_batch: false) { iteration_count += 1 }

          expect(iteration_count).to eq(9)
        end
      end
    end
  end

  context 'when use_union_optimization is used' do
    let(:iterator_params) { { scope: scope, use_union_optimization: true } }

    include_examples 'iterator examples'
  end

  context 'when use_union_optimization is not used' do
    let(:iterator_params) { { scope: scope, use_union_optimization: false } }

    include_examples 'iterator examples'
  end
end
