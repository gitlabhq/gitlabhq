# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Pagination::Keyset::SimpleOrderBuilder do
  let(:ordered_scope) { described_class.build(scope).first }
  let(:order_object) { Gitlab::Pagination::Keyset::Order.extract_keyset_order_object(ordered_scope) }
  let(:column_definition) { order_object.column_definitions.first }

  subject(:sql_with_order) { ordered_scope.to_sql }

  context 'when no order present' do
    let(:scope) { Project.where(id: [1, 2, 3]) }

    it 'orders by primary key' do
      expect(sql_with_order).to end_with('ORDER BY "projects"."id" DESC')
    end

    it 'sets the column definition distinct and not nullable' do
      expect(column_definition).to be_not_nullable
      expect(column_definition).to be_distinct
    end

    context "when the order scope's model uses default_scope" do
      let(:scope) do
        model = Class.new(ApplicationRecord) do
          self.table_name = 'events'

          default_scope { reorder(nil) } # rubocop:disable Cop/DefaultScope
        end

        model.reorder(nil)
      end

      it 'orders by primary key' do
        expect(sql_with_order).to end_with('ORDER BY "events"."id" DESC')
      end
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
      expect(column_definition.attribute_name).to eq('namespace_id')
      expect(column_definition).to be_not_nullable
      expect(column_definition).not_to be_distinct
    end
  end

  context 'when column with null check constraint is given' do
    let(:scope) { Project.where(id: [1, 2, 3]).order(name: :asc, id: :asc) }

    before do
      Project.clear_constraints_cache!
    end

    context 'when the check constraint is not valid' do
      before do
        Project.connection.execute(<<~SQL)
          ALTER TABLE projects
          ADD CONSTRAINT test_constraint CHECK (name is not null) not valid;
        SQL
      end

      it 'sets the column definition for name non-distinct and nullable' do
        expect(column_definition.attribute_name).to eq('name')
        expect(column_definition.nullable?).to be_truthy
        expect(column_definition).not_to be_distinct
      end
    end

    context 'when the check constraint is valid' do
      before do
        Project.connection.execute(<<~SQL)
          ALTER TABLE projects
          ADD CONSTRAINT test_constraint CHECK (name is not null);
        SQL
      end

      it 'sets the column definition for name non-distinct and non-nullable' do
        expect(column_definition.attribute_name).to eq('name')
        expect(column_definition).to be_not_nullable
        expect(column_definition).not_to be_distinct
      end
    end
  end

  context 'when ordering by a column with the lower named function' do
    let(:scope) { Project.where(id: [1, 2, 3]).order(Project.arel_table[:name].lower.desc) }

    it 'sets the column definition for name' do
      expect(column_definition.attribute_name).to eq('name')
      expect(column_definition.column_expression.expressions.first.name).to eq('name')
      expect(column_definition.column_expression.name).to eq('LOWER')
    end

    it 'adds extra primary key order as tie-breaker' do
      expect(sql_with_order).to end_with('ORDER BY LOWER("projects"."name") DESC, "projects"."id" DESC')
    end
  end

  context "NULLS order given as as an Arel node" do
    context 'when NULLS LAST order is given without a tie-breaker' do
      let(:scope) { Project.order(Project.arel_table[:created_at].asc.nulls_last) }

      it 'sets the column definition for created_at appropriately' do
        expect(column_definition.attribute_name).to eq('created_at')
      end

      it 'orders by primary key' do
        expect(sql_with_order).to end_with('ORDER BY "projects"."created_at" ASC NULLS LAST, "projects"."id" DESC')
      end
    end

    context 'when NULLS FIRST order is given with a tie-breaker' do
      let(:scope) { Issue.order(Issue.arel_table[:relative_position].desc.nulls_first).order(id: :asc) }

      it 'sets the column definition for created_at appropriately' do
        expect(column_definition.attribute_name).to eq('relative_position')
      end

      it 'orders by the given primary key' do
        expect(sql_with_order).to end_with('ORDER BY "issues"."relative_position" DESC NULLS FIRST, "issues"."id" ASC')
      end
    end
  end

  context 'return :unable_to_order symbol when order cannot be built' do
    subject(:success) { described_class.build(scope).last }

    context 'when raw SQL order is given' do
      let(:scope) { Project.order('id DESC') }

      it { is_expected.to eq(false) }
    end

    context 'when an invalid NULLS order is given' do
      using RSpec::Parameterized::TableSyntax

      where(:scope) do
        [
          lazy { Project.order(Arel.sql('projects.updated_at created_at Asc Nulls Last')) },
          lazy { Project.order(Arel.sql('projects.created_at ZZZ NULLS FIRST')) },
          lazy { Project.order(Arel.sql('projects.relative_position ASC NULLS LAST')) }
        ]
      end

      with_them do
        it { is_expected.to eq(false) }
      end
    end

    context 'when more than 2 columns are given for the order' do
      let(:scope) { Project.order(created_at: :asc, updated_at: :desc, id: :asc) }

      it { is_expected.to eq(true) }
    end
  end
end
