# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Graphql::Pagination::Keyset::OrderInfo do
  describe '#build_order_list' do
    let(:order_list) { described_class.build_order_list(relation) }

    context 'when multiple orders with SQL is specified' do
      let(:relation) { Project.order(Arel.sql('projects.updated_at IS NULL')).order(:updated_at).order(:id) }

      it 'ignores the SQL order' do
        expect(order_list.count).to eq 2
        expect(order_list.first.attribute_name).to eq 'updated_at'
        expect(order_list.first.operator_for(:after)).to eq '>'
        expect(order_list.last.attribute_name).to eq 'id'
        expect(order_list.last.operator_for(:after)).to eq '>'
      end
    end

    context 'when order contains NULLS LAST' do
      let(:relation) { Project.order(Arel.sql('projects.updated_at Asc Nulls Last')).order(:id) }

      it 'does not ignore the SQL order' do
        expect(order_list.count).to eq 2
        expect(order_list.first.attribute_name).to eq 'projects.updated_at'
        expect(order_list.first.operator_for(:after)).to eq '>'
        expect(order_list.last.attribute_name).to eq 'id'
        expect(order_list.last.operator_for(:after)).to eq '>'
      end
    end

    context 'when order contains invalid formatted NULLS LAST ' do
      let(:relation) { Project.order(Arel.sql('projects.updated_at created_at Asc Nulls Last')).order(:id) }

      it 'ignores the SQL order' do
        expect(order_list.count).to eq 1
      end
    end

    context 'when order contains LOWER' do
      let(:relation) { Project.order(Arel::Table.new(:projects)['name'].lower.asc).order(:id) }

      it 'does not ignore the SQL order' do
        expect(order_list.count).to eq 2
        expect(order_list.first.attribute_name).to eq 'name'
        expect(order_list.first.named_function).to be_kind_of(Arel::Nodes::NamedFunction)
        expect(order_list.first.named_function.to_sql).to eq 'LOWER("projects"."name")'
        expect(order_list.first.operator_for(:after)).to eq '>'
        expect(order_list.last.attribute_name).to eq 'id'
        expect(order_list.last.operator_for(:after)).to eq '>'
      end
    end

    context 'when ordering by CASE', :aggregate_failuers do
      let(:relation) { Project.order(Arel::Nodes::Case.new(Project.arel_table[:pending_delete]).when(true).then(100).else(1000).asc) }

      it 'assigns the right attribute name, named function, and direction' do
        expect(order_list.count).to eq 1
        expect(order_list.first.attribute_name).to eq 'case_order_value'
        expect(order_list.first.named_function).to be_kind_of(Arel::Nodes::Case)
        expect(order_list.first.sort_direction).to eq :asc
      end
    end

    context 'when ordering by ARRAY_POSITION', :aggregate_failuers do
      let(:array_position) { Arel::Nodes::NamedFunction.new('ARRAY_POSITION', [Arel.sql("ARRAY[1,0]::smallint[]"), Project.arel_table[:auto_cancel_pending_pipelines]]) }
      let(:relation) { Project.order(array_position.asc) }

      it 'assigns the right attribute name, named function, and direction' do
        expect(order_list.count).to eq 1
        expect(order_list.first.attribute_name).to eq 'array_position'
        expect(order_list.first.named_function).to be_kind_of(Arel::Nodes::NamedFunction)
        expect(order_list.first.sort_direction).to eq :asc
      end
    end
  end

  describe '#validate_ordering' do
    let(:order_list) { described_class.build_order_list(relation) }

    context 'when number of ordering fields is 0' do
      let(:relation) { Project.all }

      it 'raises an error' do
        expect { described_class.validate_ordering(relation, order_list) }
          .to raise_error(ArgumentError, 'A minimum of 1 ordering field is required')
      end
    end

    context 'when number of ordering fields is over 2' do
      let(:relation) { Project.order(last_repository_check_at: :desc).order(updated_at: :desc).order(:id) }

      it 'raises an error' do
        expect { described_class.validate_ordering(relation, order_list) }
          .to raise_error(ArgumentError, 'A maximum of 2 ordering fields are allowed')
      end
    end

    context 'when the second (or first) column is nullable' do
      let(:relation) { Project.order(last_repository_check_at: :desc).order(updated_at: :desc) }

      it 'raises an error' do
        expect { described_class.validate_ordering(relation, order_list) }
          .to raise_error(ArgumentError, "Column `updated_at` must not allow NULL")
      end
    end

    context 'for last ordering field' do
      let(:relation) { Project.order(namespace_id: :desc) }

      it 'raises error if primary key is not last field' do
        expect { described_class.validate_ordering(relation, order_list) }
          .to raise_error(ArgumentError, "Last ordering field must be the primary key, `#{relation.primary_key}`")
      end
    end
  end
end
