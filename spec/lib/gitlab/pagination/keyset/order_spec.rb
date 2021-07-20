# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Pagination::Keyset::Order do
  describe 'paginate over items correctly' do
    let(:table) { Arel::Table.new(:my_table) }
    let(:order) { nil }

    def run_query(query)
      ActiveRecord::Base.connection.execute(query).to_a
    end

    def build_query(order:, where_conditions: nil, limit: nil)
      <<-SQL
    SELECT id, year, month
      FROM (#{table_data}) my_table (id, year, month) 
      WHERE #{where_conditions || '1=1'} 
      ORDER BY #{order} 
      LIMIT #{limit || 999};
      SQL
    end

    def iterate_and_collect(order:, page_size:, where_conditions: nil)
      all_items = []

      loop do
        paginated_items = run_query(build_query(order: order, where_conditions: where_conditions, limit: page_size))
        break if paginated_items.empty?

        all_items.concat(paginated_items)
        last_item = paginated_items.last
        cursor_attributes = order.cursor_attributes_for_node(last_item)
        where_conditions = order.where_values_with_or_query(cursor_attributes).to_sql
      end

      all_items
    end

    subject do
      run_query(build_query(order: order))
    end

    shared_examples 'order examples' do
      it { expect(subject).to eq(expected) }

      context 'when paginating forwards' do
        subject { iterate_and_collect(order: order, page_size: 2) }

        it { expect(subject).to eq(expected) }

        context 'with different page size' do
          subject { iterate_and_collect(order: order, page_size: 5) }

          it { expect(subject).to eq(expected) }
        end
      end

      context 'when paginating backwards' do
        subject do
          last_item = expected.last
          cursor_attributes = order.cursor_attributes_for_node(last_item)
          where_conditions = order.reversed_order.where_values_with_or_query(cursor_attributes)

          iterate_and_collect(order: order.reversed_order, page_size: 2, where_conditions: where_conditions.to_sql)
        end

        it do
          expect(subject).to eq(expected.reverse[1..-1]) # removing one item because we used it to calculate cursor data for the "last" page in subject
        end
      end
    end

    context 'when ordering by a distinct column' do
      let(:table_data) do
        <<-SQL
      VALUES (1,  0, 0),
             (2,  0, 0),
             (3,  0, 0),
             (4,  0, 0),
             (5,  0, 0),
             (6,  0, 0),
             (7,  0, 0),
             (8,  0, 0),
             (9,  0, 0)
        SQL
      end

      let(:order) do
        Gitlab::Pagination::Keyset::Order.build([
          Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
            attribute_name: 'id',
            column_expression: table['id'],
            order_expression: table['id'].desc,
            nullable: :not_nullable,
            distinct: true
          )
        ])
      end

      let(:expected) do
        [
          { "id" => 9, "year" => 0, "month" => 0 },
          { "id" => 8, "year" => 0, "month" => 0 },
          { "id" => 7, "year" => 0, "month" => 0 },
          { "id" => 6, "year" => 0, "month" => 0 },
          { "id" => 5, "year" => 0, "month" => 0 },
          { "id" => 4, "year" => 0, "month" => 0 },
          { "id" => 3, "year" => 0, "month" => 0 },
          { "id" => 2, "year" => 0, "month" => 0 },
          { "id" => 1, "year" => 0, "month" => 0 }
        ]
      end

      it_behaves_like 'order examples'
    end

    context 'when ordering by two non-nullable columns and a distinct column' do
      let(:table_data) do
        <<-SQL
      VALUES (1,  2010, 2),
             (2,  2011, 1),
             (3,  2009, 2),
             (4,  2011, 1),
             (5,  2011, 1),
             (6,  2009, 2),
             (7,  2010, 3),
             (8,  2012, 4),
             (9,  2013, 5)
        SQL
      end

      let(:order) do
        Gitlab::Pagination::Keyset::Order.build([
          Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
            attribute_name: 'year',
            column_expression: table['year'],
            order_expression: table['year'].asc,
            nullable: :not_nullable,
            distinct: false
          ),
          Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
            attribute_name: 'month',
            column_expression: table['month'],
            order_expression: table['month'].asc,
            nullable: :not_nullable,
            distinct: false
          ),
          Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
            attribute_name: 'id',
            column_expression: table['id'],
            order_expression: table['id'].asc,
            nullable: :not_nullable,
            distinct: true
          )
        ])
      end

      let(:expected) do
        [
          { 'year' => 2009, 'month' => 2, 'id' => 3 },
          { 'year' => 2009, 'month' => 2, 'id' => 6 },
          { 'year' => 2010, 'month' => 2, 'id' => 1 },
          { 'year' => 2010, 'month' => 3, 'id' => 7 },
          { 'year' => 2011, 'month' => 1, 'id' => 2 },
          { 'year' => 2011, 'month' => 1, 'id' => 4 },
          { 'year' => 2011, 'month' => 1, 'id' => 5 },
          { 'year' => 2012, 'month' => 4, 'id' => 8 },
          { 'year' => 2013, 'month' => 5, 'id' => 9 }
        ]
      end

      it_behaves_like 'order examples'

      it 'uses the row comparison method' do
        sql = order.where_values_with_or_query({ year: 2010, month: 5, id: 1 }).to_sql

        expect(sql).to eq('(("my_table"."year", "my_table"."month", "my_table"."id") > (2010, 5, 1))')
      end
    end

    context 'when ordering by nullable columns and a distinct column' do
      let(:table_data) do
        <<-SQL
      VALUES (1,  2010, null),
             (2,  2011, 2),
             (3,  null, null),
             (4,  null, 5),
             (5,  2010, null),
             (6,  2011, 2),
             (7,  2010, 2),
             (8,  2012, 2),
             (9,  null, 2),
             (10, null, null),
             (11, 2010, 2)
        SQL
      end

      let(:order) do
        Gitlab::Pagination::Keyset::Order.build([
          Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
            attribute_name: 'year',
            column_expression: table['year'],
            order_expression: Gitlab::Database.nulls_last_order('year', :asc),
            reversed_order_expression: Gitlab::Database.nulls_first_order('year', :desc),
            order_direction: :asc,
            nullable: :nulls_last,
            distinct: false
          ),
          Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
            attribute_name: 'month',
            column_expression: table['month'],
            order_expression: Gitlab::Database.nulls_last_order('month', :asc),
            reversed_order_expression: Gitlab::Database.nulls_first_order('month', :desc),
            order_direction: :asc,
            nullable: :nulls_last,
            distinct: false
          ),
          Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
            attribute_name: 'id',
            column_expression: table['id'],
            order_expression: table['id'].asc,
            nullable: :not_nullable,
            distinct: true
          )
        ])
      end

      let(:expected) do
        [
          { "id" => 7, "year" => 2010, "month" => 2 },
          { "id" => 11, "year" => 2010, "month" => 2 },
          { "id" => 1, "year" => 2010, "month" => nil },
          { "id" => 5, "year" => 2010, "month" => nil },
          { "id" => 2, "year" => 2011, "month" => 2 },
          { "id" => 6, "year" => 2011, "month" => 2 },
          { "id" => 8, "year" => 2012, "month" => 2 },
          { "id" => 9, "year" => nil, "month" => 2 },
          { "id" => 4, "year" => nil, "month" => 5 },
          { "id" => 3, "year" => nil, "month" => nil },
          { "id" => 10, "year" => nil, "month" => nil }
        ]
      end

      it_behaves_like 'order examples'
    end

    context 'when ordering by nullable columns with nulls first ordering and a distinct column' do
      let(:table_data) do
        <<-SQL
      VALUES (1,  2010, null),
             (2,  2011, 2),
             (3,  null, null),
             (4,  null, 5),
             (5,  2010, null),
             (6,  2011, 2),
             (7,  2010, 2),
             (8,  2012, 2),
             (9,  null, 2),
             (10, null, null),
             (11, 2010, 2)
        SQL
      end

      let(:order) do
        Gitlab::Pagination::Keyset::Order.build([
          Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
            attribute_name: 'year',
            column_expression: table['year'],
            order_expression: Gitlab::Database.nulls_first_order('year', :asc),
            reversed_order_expression: Gitlab::Database.nulls_last_order('year', :desc),
            order_direction: :asc,
            nullable: :nulls_first,
            distinct: false
          ),
          Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
            attribute_name: 'month',
            column_expression: table['month'],
            order_expression: Gitlab::Database.nulls_first_order('month', :asc),
            order_direction: :asc,
            reversed_order_expression: Gitlab::Database.nulls_last_order('month', :desc),
            nullable: :nulls_first,
            distinct: false
          ),
          Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
            attribute_name: 'id',
            column_expression: table['id'],
            order_expression: table['id'].asc,
            nullable: :not_nullable,
            distinct: true
          )
        ])
      end

      let(:expected) do
        [
          { "id" => 3, "year" => nil, "month" => nil },
          { "id" => 10, "year" => nil, "month" => nil },
          { "id" => 9, "year" => nil, "month" => 2 },
          { "id" => 4, "year" => nil, "month" => 5 },
          { "id" => 1, "year" => 2010, "month" => nil },
          { "id" => 5, "year" => 2010, "month" => nil },
          { "id" => 7, "year" => 2010, "month" => 2 },
          { "id" => 11, "year" => 2010, "month" => 2 },
          { "id" => 2, "year" => 2011, "month" => 2 },
          { "id" => 6, "year" => 2011, "month" => 2 },
          { "id" => 8, "year" => 2012, "month" => 2 }
        ]
      end

      it_behaves_like 'order examples'
    end

    context 'when ordering by non-nullable columns with mixed directions and a distinct column' do
      let(:table_data) do
        <<-SQL
      VALUES (1,  2010, 0),
             (2,  2011, 0),
             (3,  2010, 0),
             (4,  2010, 0),
             (5,  2012, 0),
             (6,  2012, 0),
             (7,  2010, 0),
             (8,  2011, 0),
             (9,  2013, 0),
             (10, 2014, 0),
             (11, 2013, 0)
        SQL
      end

      let(:order) do
        Gitlab::Pagination::Keyset::Order.build([
          Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
            attribute_name: 'year',
            column_expression: table['year'],
            order_expression: table['year'].asc,
            nullable: :not_nullable,
            distinct: false
          ),
          Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
            attribute_name: 'id',
            column_expression: table['id'],
            order_expression: table['id'].desc,
            nullable: :not_nullable,
            distinct: true
          )
        ])
      end

      let(:expected) do
        [
          { "id" => 7, "year" => 2010, "month" => 0 },
          { "id" => 4, "year" => 2010, "month" => 0 },
          { "id" => 3, "year" => 2010, "month" => 0 },
          { "id" => 1, "year" => 2010, "month" => 0 },
          { "id" => 8, "year" => 2011, "month" => 0 },
          { "id" => 2, "year" => 2011, "month" => 0 },
          { "id" => 6, "year" => 2012, "month" => 0 },
          { "id" => 5, "year" => 2012, "month" => 0 },
          { "id" => 11, "year" => 2013, "month" => 0 },
          { "id" => 9, "year" => 2013, "month" => 0 },
          { "id" => 10, "year" => 2014, "month" => 0 }
        ]
      end

      it 'takes out a slice between two cursors' do
        after_cursor = { "id" => 8, "year" => 2011 }
        before_cursor = { "id" => 5, "year" => 2012 }

        after_conditions = order.where_values_with_or_query(after_cursor)
        reversed = order.reversed_order
        before_conditions = reversed.where_values_with_or_query(before_cursor)

        query = build_query(order: order, where_conditions: "(#{after_conditions.to_sql}) AND (#{before_conditions.to_sql})", limit: 100)

        expect(run_query(query)).to eq([
          { "id" => 2, "year" => 2011, "month" => 0 },
          { "id" => 6, "year" => 2012, "month" => 0 }
        ])
      end
    end

    context 'when the passed cursor values do not match with the order definition' do
      let(:order) do
        Gitlab::Pagination::Keyset::Order.build([
          Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
            attribute_name: 'year',
            column_expression: table['year'],
            order_expression: table['year'].asc,
            nullable: :not_nullable,
            distinct: false
          ),
          Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
            attribute_name: 'id',
            column_expression: table['id'],
            order_expression: table['id'].desc,
            nullable: :not_nullable,
            distinct: true
          )
        ])
      end

      context 'when values are missing' do
        it 'raises error'  do
          expect { order.build_where_values(id: 1) }.to raise_error(/Missing items: year/)
        end
      end

      context 'when extra values are present' do
        it 'raises error' do
          expect { order.build_where_values(id: 1, year: 2, foo: 3) }.to raise_error(/Extra items: foo/)
        end
      end

      context 'when values are missing and extra values are present' do
        it 'raises error'  do
          expect { order.build_where_values(year: 2, foo: 3) }.to raise_error(/Extra items: foo\. Missing items: id/)
        end
      end

      context 'when no values are passed' do
        it 'returns empty array' do
          expect(order.build_where_values({})).to eq([])
        end
      end
    end

    context 'extract and apply cursor attributes' do
      let(:model) { Project.new(id: 100) }
      let(:scope) { Project.all }

      shared_examples 'cursor attribute examples' do
        describe '#cursor_attributes_for_node' do
          it { expect(order.cursor_attributes_for_node(model)).to eq({ id: '100' }.with_indifferent_access) }
        end

        describe '#apply_cursor_conditions' do
          context 'when params with string keys are passed' do
            subject(:sql) { order.apply_cursor_conditions(scope, { 'id' => '100' }).to_sql }

            it { is_expected.to include('"projects"."id" < 100)') }
          end

          context 'when params with symbol keys are passed' do
            subject(:sql) { order.apply_cursor_conditions(scope, { id: '100' }).to_sql }

            it { is_expected.to include('"projects"."id" < 100)') }
          end
        end
      end

      context 'when string attribute name is given' do
        let(:order) do
          Gitlab::Pagination::Keyset::Order.build([
            Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
              attribute_name: 'id',
              order_expression: Project.arel_table['id'].desc,
              nullable: :not_nullable,
              distinct: true
            )
          ])
        end

        it_behaves_like 'cursor attribute examples'
      end

      context 'when symbol attribute name is given' do
        let(:order) do
          Gitlab::Pagination::Keyset::Order.build([
            Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
              attribute_name: :id,
              order_expression: Project.arel_table['id'].desc,
              nullable: :not_nullable,
              distinct: true
            )
          ])
        end

        it_behaves_like 'cursor attribute examples'
      end
    end
  end

  describe 'UNION optimization' do
    let_it_be(:five_months_ago) { 5.months.ago }

    let_it_be(:user_1) { create(:user, created_at: five_months_ago) }
    let_it_be(:user_2) { create(:user, created_at: five_months_ago) }
    let_it_be(:user_3) { create(:user, created_at: 1.month.ago) }
    let_it_be(:user_4) { create(:user, created_at: 2.months.ago) }

    let(:expected_results) { [user_3, user_4, user_2, user_1] }
    let(:scope) { User.order(created_at: :desc, id: :desc) }
    let(:keyset_aware_scope) { Gitlab::Pagination::Keyset::SimpleOrderBuilder.build(scope).first }
    let(:iterator_options) { { scope: keyset_aware_scope } }

    subject(:items) do
      [].tap do |collector|
        Gitlab::Pagination::Keyset::Iterator.new(**iterator_options).each_batch(of: 2) do |models|
          collector.concat(models)
        end
      end
    end

    context 'when UNION optimization is off' do
      it 'returns items in the correct order' do
        iterator_options[:use_union_optimization] = false

        expect(items).to eq(expected_results)
      end
    end

    context 'when UNION optimization is on' do
      before do
        iterator_options[:use_union_optimization] = true
      end

      it 'returns items in the correct order' do
        expect(items).to eq(expected_results)
      end

      it 'calls Gitlab::SQL::Union' do
        expect_next_instances_of(Gitlab::SQL::Union, 2) do |instance|
          expect(instance.send(:remove_order)).to eq(false) # Do not remove order from the queries
          expect(instance.send(:remove_duplicates)).to eq(false) # Do not deduplicate the results
        end

        items
      end

      it 'builds UNION query' do
        cursor_attributes = { created_at: five_months_ago, id: user_2.id }
        order = Gitlab::Pagination::Keyset::Order.extract_keyset_order_object(keyset_aware_scope)

        query = order.apply_cursor_conditions(scope, cursor_attributes, use_union_optimization: true).to_sql
        expect(query).to include('UNION ALL')
      end
    end
  end
end
