# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Pagination::Keyset::SimpleOrderBuilder do
  let(:ordered_scope) { described_class.build(scope).first }
  let(:order_object) { Gitlab::Pagination::Keyset::Order.extract_keyset_order_object(ordered_scope) }

  subject(:sql_with_order) { ordered_scope.to_sql }

  context 'when no order present' do
    let(:scope) { Project.where(id: [1, 2, 3]) }

    it 'orders by primary key' do
      expect(sql_with_order).to end_with('ORDER BY "projects"."id" DESC')
    end

    it 'sets the column definition distinct and not nullable' do
      column_definition = order_object.column_definitions.first

      expect(column_definition).to be_not_nullable
      expect(column_definition).to be_distinct
    end
  end

  context 'when primary key order present' do
    let(:scope) { Project.where(id: [1, 2, 3]).order(id: :asc) }

    it 'orders by primary key without altering the direction' do
      expect(sql_with_order).to end_with('ORDER BY "projects"."id" ASC')
    end
  end

  context 'when ordered by other column' do
    let(:scope) { Project.where(id: [1, 2, 3]).order(created_at: :asc) }

    it 'adds extra primary key order as tie-breaker' do
      expect(sql_with_order).to end_with('ORDER BY "projects"."created_at" ASC, "projects"."id" DESC')
    end

    it 'sets the column definition for created_at non-distinct and nullable' do
      column_definition = order_object.column_definitions.first

      expect(column_definition.attribute_name).to eq('created_at')
      expect(column_definition.nullable?).to eq(true) # be_nullable calls non_null? method for some reason
      expect(column_definition).not_to be_distinct
    end
  end

  context 'when ordered by two columns where the last one is the tie breaker' do
    let(:scope) { Project.where(id: [1, 2, 3]).order(created_at: :asc, id: :asc) }

    it 'preserves the order' do
      expect(sql_with_order).to end_with('ORDER BY "projects"."created_at" ASC, "projects"."id" ASC')
    end
  end

  context 'when non-nullable column is given' do
    let(:scope) { Project.where(id: [1, 2, 3]).order(namespace_id: :asc, id: :asc) }

    it 'sets the column definition for namespace_id non-distinct and non-nullable' do
      column_definition = order_object.column_definitions.first

      expect(column_definition.attribute_name).to eq('namespace_id')
      expect(column_definition).to be_not_nullable
      expect(column_definition).not_to be_distinct
    end
  end

  context 'return :unable_to_order symbol when order cannot be built' do
    subject(:success) { described_class.build(scope).last }

    context 'when raw SQL order is given' do
      let(:scope) { Project.order('id DESC') }

      it { is_expected.to eq(false) }
    end

    context 'when NULLS LAST order is given' do
      let(:scope) { Project.order(::Gitlab::Database.nulls_last_order('created_at', 'ASC')) }

      it { is_expected.to eq(false) }
    end

    context 'when more than 2 columns are given for the order' do
      let(:scope) { Project.order(created_at: :asc, updated_at: :desc, id: :asc) }

      it { is_expected.to eq(false) }
    end
  end
end
