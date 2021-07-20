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
    Gitlab::Pagination::Keyset::Order.build([
      Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
        attribute_name: column,
        column_expression: klass.arel_table[column],
        order_expression: ::Gitlab::Database.nulls_order(column, direction, nulls_position),
        reversed_order_expression: ::Gitlab::Database.nulls_order(column, reverse_direction, reverse_nulls_position),
        order_direction: direction,
        nullable: nulls_position,
        distinct: false
      ),
      Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
        attribute_name: 'id',
        order_expression: klass.arel_table[:id].send(direction)
      )
    ])
  end

  let(:scope) { project.issues.reorder(custom_reorder) }

  shared_examples 'iterator examples' do
    describe '.each_batch' do
      it 'yields an ActiveRecord::Relation when a block is given' do
        iterator.each_batch(of: 1) do |relation|
          expect(relation).to be_a_kind_of(ActiveRecord::Relation)
        end
      end

      it 'raises error when ordering configuration cannot be automatically determined' do
        expect do
          described_class.new(scope: MergeRequestDiffCommit.order(:merge_request_diff_id, :relative_order))
        end.to raise_error /The order on the scope does not support keyset pagination/
      end

      it 'accepts a custom batch size' do
        count = 0

        iterator.each_batch(of: 2) { |relation| count += relation.count(:all) }

        expect(count).to eq(9)
      end

      it 'allows updating of the yielded relations' do
        time = Time.current

        iterator.each_batch(of: 2) do |relation|
          Issue.connection.execute("UPDATE issues SET updated_at = '#{time.to_s(:inspect)}' WHERE id IN (#{relation.reselect(:id).to_sql})")
        end

        expect(Issue.pluck(:updated_at)).to all(be_within(5.seconds).of(time))
      end

      context 'with ordering direction' do
        context 'when ordering asc' do
          it 'orders ascending by default, including secondary order column' do
            positions = []

            iterator.each_batch(of: 2) { |rel| positions.concat(rel.pluck(:relative_position, :id)) }

            expect(positions).to eq(project.issues.order_relative_position_asc.order(id: :asc).pluck(:relative_position, :id))
          end
        end

        context 'when reversing asc order' do
          let(:scope) { project.issues.order(custom_reorder.reversed_order) }

          it 'orders in reverse of ascending' do
            positions = []

            iterator.each_batch(of: 2) { |rel| positions.concat(rel.pluck(:relative_position, :id)) }

            expect(positions).to eq(project.issues.order_relative_position_desc.order(id: :desc).pluck(:relative_position, :id))
          end
        end

        context 'when asc order, with nulls first' do
          let(:nulls_position) { :nulls_first }

          it 'orders ascending with nulls first' do
            positions = []

            iterator.each_batch(of: 2) { |rel| positions.concat(rel.pluck(:relative_position, :id)) }

            expect(positions).to eq(project.issues.reorder(::Gitlab::Database.nulls_first_order('relative_position', 'ASC')).order(id: :asc).pluck(:relative_position, :id))
          end
        end

        context 'when ordering desc' do
          let(:direction) { :desc }
          let(:nulls_position) { :nulls_last }

          it 'orders descending' do
            positions = []

            iterator.each_batch(of: 2) { |rel| positions.concat(rel.pluck(:relative_position, :id)) }

            expect(positions).to eq(project.issues.reorder(::Gitlab::Database.nulls_last_order('relative_position', 'DESC')).order(id: :desc).pluck(:relative_position, :id))
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
    end
  end

  context 'when use_union_optimization is used' do
    subject(:iterator) { described_class.new(scope: scope, use_union_optimization: true) }

    include_examples 'iterator examples'
  end

  context 'when use_union_optimization is not used' do
    subject(:iterator) { described_class.new(scope: scope, use_union_optimization: false) }

    include_examples 'iterator examples'
  end
end
