# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Graphql::Connections::Keyset::OrderInfo do
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
