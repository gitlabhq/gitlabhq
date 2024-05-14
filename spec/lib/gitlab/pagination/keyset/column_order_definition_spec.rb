# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Pagination::Keyset::ColumnOrderDefinition do
  let_it_be(:project_name_column) do
    described_class.new(
      attribute_name: :name,
      order_expression: Project.arel_table[:name].asc,
      nullable: :not_nullable
    )
  end

  let_it_be(:project_name_lower_column) do
    described_class.new(
      attribute_name: :name,
      order_expression: Project.arel_table[:name].lower.desc,
      nullable: :not_nullable
    )
  end

  let_it_be(:project_calculated_column_expression) do
    # COALESCE("projects"."description", 'No Description')
    Arel::Nodes::NamedFunction.new('COALESCE',
      [
        Project.arel_table[:description],
        Arel.sql("'No Description'")
      ])
  end

  let_it_be(:project_calculated_column) do
    described_class.new(
      attribute_name: :name,
      column_expression: project_calculated_column_expression,
      order_expression: project_calculated_column_expression.asc,
      nullable: :not_nullable
    )
  end

  describe '#order_direction' do
    context 'inferring order_direction from order_expression' do
      it { expect(project_name_column).to be_ascending_order }
      it { expect(project_name_column).not_to be_descending_order }

      it { expect(project_name_lower_column).to be_descending_order }
      it { expect(project_name_lower_column).not_to be_ascending_order }

      it { expect(project_calculated_column).to be_ascending_order }
      it { expect(project_calculated_column).not_to be_descending_order }

      context 'when order expression is an Arel node with nulls_last' do
        it 'can automatically determine the reversed expression' do
          column_order_definition = described_class.new(
            attribute_name: :name,
            column_expression: Project.arel_table[:name],
            order_expression: Project.arel_table[:name].asc.nulls_last,
            nullable: :nulls_last
          )

          expect(column_order_definition).to be_ascending_order
        end
      end

      it 'raises error when order direction cannot be infered' do
        expect do
          described_class.new(
            attribute_name: :name,
            column_expression: Project.arel_table[:name],
            order_expression: 'name asc',
            reversed_order_expression: 'name desc',
            nullable: :not_nullable
          )
        end.to raise_error(RuntimeError, /Invalid or missing `order_direction`/)
      end

      it 'does not raise error when order direction is explicitly given' do
        column_order_definition = described_class.new(
          attribute_name: :name,
          column_expression: Project.arel_table[:name],
          order_expression: 'name asc',
          reversed_order_expression: 'name desc',
          order_direction: :asc,
          nullable: :not_nullable
        )

        expect(column_order_definition).to be_ascending_order
      end
    end
  end

  describe '#column_expression' do
    context 'inferring column_expression from order_expression' do
      it 'infers the correct column expression' do
        column_order_definition = described_class.new(attribute_name: :name, order_expression: Project.arel_table[:name].asc)

        expect(column_order_definition.column_expression).to eq(Project.arel_table[:name])
      end

      it 'raises error when raw string is given as order expression' do
        expect do
          described_class.new(attribute_name: :name, order_expression: 'name DESC')
        end.to raise_error(RuntimeError, /Couldn't calculate the column expression. Please pass an ARel node/)
      end
    end
  end

  describe '#reversed_order_expression' do
    it 'raises error when order cannot be reversed automatically' do
      expect do
        described_class.new(
          attribute_name: :name,
          column_expression: Project.arel_table[:name],
          order_expression: 'name asc',
          order_direction: :asc,
          nullable: :not_nullable
        )
      end.to raise_error(RuntimeError, /Couldn't determine reversed order/)
    end
  end

  describe '#reverse' do
    it { expect(project_name_column.reverse.order_expression).to eq(Project.arel_table[:name].desc) }
    it { expect(project_name_column.reverse).to be_descending_order }

    it { expect(project_calculated_column.reverse.order_expression).to eq(project_calculated_column_expression.desc) }
    it { expect(project_calculated_column.reverse).to be_descending_order }

    context 'when reversed_order_expression is given' do
      it 'uses the given expression' do
        column_order_definition = described_class.new(
          attribute_name: :name,
          column_expression: Project.arel_table[:name],
          order_expression: 'name asc',
          reversed_order_expression: 'name desc',
          order_direction: :asc,
          nullable: :not_nullable
        )

        expect(column_order_definition.reverse.order_expression).to eq('name desc')
      end
    end

    context 'when order expression is an Arel node with nulls_last' do
      it 'can automatically determine the reversed expression' do
        column_order_definition = described_class.new(
          attribute_name: :name,
          column_expression: Project.arel_table[:name],
          order_expression: Project.arel_table[:name].asc.nulls_last,
          order_direction: :asc,
          nullable: :nulls_last
        )

        expect(column_order_definition.reverse.order_expression).to eq(Project.arel_table[:name].desc.nulls_first)
      end
    end
  end

  describe '#nullable' do
    context 'when the column is nullable' do
      let(:nulls_last_order) do
        described_class.new(
          attribute_name: :name,
          column_expression: Project.arel_table[:name],
          order_expression: MergeRequest::Metrics.arel_table[:merged_at].desc.nulls_last,
          reversed_order_expression: MergeRequest::Metrics.arel_table[:merged_at].asc.nulls_first,
          order_direction: :desc,
          nullable: :nulls_last # null values are always last
        )
      end

      it 'requires the position of the null values in the result' do
        expect(nulls_last_order).to be_nulls_last
      end

      it 'reverses nullable correctly' do
        expect(nulls_last_order.reverse).to be_nulls_first
      end

      it 'raises error when invalid nullable value is given' do
        expect do
          described_class.new(
            attribute_name: :name,
            column_expression: Project.arel_table[:name],
            order_expression: MergeRequest::Metrics.arel_table[:merged_at].desc.nulls_last,
            reversed_order_expression: MergeRequest::Metrics.arel_table[:merged_at].asc.nulls_first,
            order_direction: :desc,
            nullable: true
          )
        end.to raise_error(RuntimeError, /Invalid `nullable` is given/)
      end
    end
  end

  describe "#order_direction_as_sql_string" do
    let(:nulls_last_order) do
      described_class.new(
        attribute_name: :name,
        column_expression: Project.arel_table[:name],
        order_expression: MergeRequest::Metrics.arel_table[:merged_at].desc.nulls_last,
        reversed_order_expression: MergeRequest::Metrics.arel_table[:merged_at].asc.nulls_first,
        order_direction: :desc,
        nullable: :nulls_last # null values are always last
      )
    end

    it { expect(project_name_column.order_direction_as_sql_string).to eq('ASC') }
    it { expect(project_name_column.reverse.order_direction_as_sql_string).to eq('DESC') }
    it { expect(project_name_lower_column.order_direction_as_sql_string).to eq('DESC') }
    it { expect(project_name_lower_column.reverse.order_direction_as_sql_string).to eq('ASC') }
    it { expect(nulls_last_order.order_direction_as_sql_string).to eq('DESC NULLS LAST') }
    it { expect(nulls_last_order.reverse.order_direction_as_sql_string).to eq('ASC NULLS FIRST') }
  end
end
