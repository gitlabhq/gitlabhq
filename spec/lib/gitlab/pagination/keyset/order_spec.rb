# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Pagination::Keyset::Order do
  describe 'paginate over items correctly' do
    let(:table) { Arel::Table.new(:my_table) }
    let(:order) { nil }
    let(:default_limit) { 999 }
    let(:query_building_method) { :build_query }

    def run_query(query)
      ApplicationRecord.connection.execute(query).to_a
    end

    def where_conditions_as_sql(where_conditions)
      "WHERE #{Array(where_conditions).map(&:to_sql).join(' OR ')}"
    end

    def build_query(order:, where_conditions: [], limit: nil)
      where_string = where_conditions_as_sql(where_conditions)

      <<-SQL
        SELECT id, year, month
        FROM (#{table_data}) my_table (id, year, month)
        #{where_string if where_conditions.present?}
        ORDER BY #{order}
        LIMIT #{limit || default_limit};
      SQL
    end

    def build_union_query(order:, where_conditions: [], limit: nil)
      return build_query(order: order, where_conditions: where_conditions, limit: limit) if where_conditions.blank?

      union_queries = Array(where_conditions).map do |where_condition|
        <<-SQL
          (SELECT id, year, month
            FROM (#{table_data}) my_table (id, year, month)
            WHERE #{where_condition.to_sql}
            ORDER BY #{order}
            LIMIT #{limit || default_limit})
        SQL
      end

      union_query = union_queries.join(" UNION ALL ")

      <<-SQL
        SELECT id, year, month
        FROM (#{union_query}) as my_table
        ORDER BY #{order}
        LIMIT #{limit || default_limit};
      SQL
    end

    def cursor_attributes_for_node(node)
      order.cursor_attributes_for_node(node)
    end

    def iterate_and_collect(order:, page_size:, where_conditions: nil)
      all_items = []

      loop do
        paginated_items = run_query(send(query_building_method, order: order, where_conditions: where_conditions, limit: page_size))
        break if paginated_items.empty?

        all_items.concat(paginated_items)
        last_item = paginated_items.last
        cursor_attributes = cursor_attributes_for_node(last_item)
        where_conditions = order.build_where_values(cursor_attributes)
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

        context 'when using the conditions in an UNION query' do
          let(:query_building_method) { :build_union_query }

          it { expect(subject).to eq(expected) }
        end

        context 'when the cursor attributes are SQL literals' do
          def cursor_attributes_for_node(node)
            # Simulate the scenario where the cursor attributes are SQL literals
            order.cursor_attributes_for_node(node).transform_values.each_with_index do |value, i|
              index = i + 1
              value_sql = value.nil? ? 'NULL::integer' : value
              values = [value_sql] * index
              Arel.sql("(ARRAY[#{values.join(',')}])[#{index}]") # example: ARRAY[cursor_value][1] will return cursor_value
            end
          end

          it { expect(subject).to eq(expected) }

          context 'when using the conditions in an UNION query' do
            let(:query_building_method) { :build_union_query }

            it { expect(subject).to eq(expected) }
          end
        end
      end

      context 'when paginating backwards' do
        subject do
          last_item = expected.last
          cursor_attributes = order.cursor_attributes_for_node(last_item)
          where_conditions = order.reversed_order.build_where_values(cursor_attributes)

          iterate_and_collect(order: order.reversed_order, page_size: 2, where_conditions: where_conditions)
        end

        it do
          expect(subject).to eq(expected.reverse[1..]) # removing one item because we used it to calculate cursor data for the "last" page in subject
        end
      end
    end

    context 'when ordering by a unique column' do
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
        described_class.build(
          [
            Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
              attribute_name: 'id',
              column_expression: table['id'],
              order_expression: table['id'].desc,
              nullable: :not_nullable
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

    context 'when ordering by two non-nullable columns' do
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
        described_class.build(
          [
            Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
              attribute_name: 'year',
              column_expression: table['year'],
              order_expression: table['year'].asc,
              nullable: :not_nullable
            ),
            Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
              attribute_name: 'month',
              column_expression: table['month'],
              order_expression: table['month'].asc,
              nullable: :not_nullable
            ),
            Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
              attribute_name: 'id',
              column_expression: table['id'],
              order_expression: table['id'].asc,
              nullable: :not_nullable
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

    context 'when ordering by nullable columns' do
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
        described_class.build(
          [
            Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
              attribute_name: 'year',
              column_expression: table['year'],
              order_expression: table[:year].asc.nulls_last,
              reversed_order_expression: table[:year].desc.nulls_first,
              order_direction: :asc,
              nullable: :nulls_last
            ),
            Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
              attribute_name: 'month',
              column_expression: table['month'],
              order_expression: table[:month].asc.nulls_last,
              reversed_order_expression: table[:month].desc.nulls_first,
              order_direction: :asc,
              nullable: :nulls_last
            ),
            Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
              attribute_name: 'id',
              column_expression: table['id'],
              order_expression: table['id'].asc,
              nullable: :not_nullable
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

    context 'when ordering by nullable columns with nulls first ordering' do
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
        described_class.build(
          [
            Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
              attribute_name: 'year',
              column_expression: table['year'],
              order_expression: table[:year].asc.nulls_first,
              reversed_order_expression: table[:year].desc.nulls_last,
              order_direction: :asc,
              nullable: :nulls_first
            ),
            Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
              attribute_name: 'month',
              column_expression: table['month'],
              order_expression: table[:month].asc.nulls_first,
              order_direction: :asc,
              reversed_order_expression: table[:month].desc.nulls_last,
              nullable: :nulls_first
            ),
            Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
              attribute_name: 'id',
              column_expression: table['id'],
              order_expression: table['id'].asc,
              nullable: :not_nullable
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

    context 'when ordering by non-nullable columns with mixed directions' do
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
        described_class.build(
          [
            Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
              attribute_name: 'year',
              column_expression: table['year'],
              order_expression: table['year'].asc,
              nullable: :not_nullable
            ),
            Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
              attribute_name: 'id',
              column_expression: table['id'],
              order_expression: table['id'].desc,
              nullable: :not_nullable
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

        query = build_query(
          order: order,
          where_conditions: [Arel::Nodes::And.new([after_conditions, before_conditions])],
          limit: 100)

        expect(run_query(query)).to eq(
          [
            { "id" => 2, "year" => 2011, "month" => 0 },
            { "id" => 6, "year" => 2012, "month" => 0 }
          ])
      end
    end

    context 'when ordering by the named function LOWER' do
      let(:order) do
        described_class.build(
          [
            Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
              attribute_name: 'title',
              column_expression: Arel::Nodes::NamedFunction.new("LOWER", [table['title'].desc]),
              order_expression: table['title'].lower.desc,
              nullable: :not_nullable
            ),
            Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
              attribute_name: 'id',
              column_expression: table['id'],
              order_expression: table['id'].desc,
              nullable: :not_nullable
            )
          ])
      end

      let(:table_data) do
        <<-SQL
      VALUES (1,  'A')
        SQL
      end

      let(:query) do
        <<-SQL
          SELECT id, title
          FROM (#{table_data}) my_table (id, title)
          ORDER BY #{order};
        SQL
      end

      subject { run_query(query) }

      it "uses downcased value for encoding and decoding a cursor" do
        expect(order.cursor_attributes_for_node(subject.first)['title']).to eq("a")
      end
    end

    context 'when the passed cursor values do not match with the order definition' do
      let(:order) do
        described_class.build(
          [
            Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
              attribute_name: 'year',
              column_expression: table['year'],
              order_expression: table['year'].asc,
              nullable: :not_nullable
            ),
            Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
              attribute_name: 'id',
              column_expression: table['id'],
              order_expression: table['id'].desc,
              nullable: :not_nullable
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
          described_class.build(
            [
              Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
                attribute_name: 'id',
                order_expression: Project.arel_table['id'].desc,
                nullable: :not_nullable
              )
            ])
        end

        it_behaves_like 'cursor attribute examples'
      end

      context 'when symbol attribute name is given' do
        let(:order) do
          described_class.build(
            [
              Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
                attribute_name: :id,
                order_expression: Project.arel_table['id'].desc,
                nullable: :not_nullable
              )
            ])
        end

        it_behaves_like 'cursor attribute examples'

        context 'with projections' do
          context 'when additional_projections is empty' do
            let(:scope) { Project.select(:id, :namespace_id) }

            subject(:sql) { order.apply_cursor_conditions(scope, { id: '100' }).to_sql }

            it 'has correct projections' do
              is_expected.to include('SELECT "projects"."id", "projects"."namespace_id" FROM "projects"')
            end
          end

          context 'when there are additional_projections' do
            let(:order) do
              order = described_class.build(
                [
                  Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
                    attribute_name: 'created_at_field',
                    column_expression: Project.arel_table[:created_at],
                    order_expression: Project.arel_table[:created_at].desc,
                    order_direction: :desc,
                    add_to_projections: true
                  ),
                  Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
                    attribute_name: 'id',
                    order_expression: Project.arel_table[:id].desc
                  )
                ])

              order
            end

            let(:scope) { Project.select(:id, :namespace_id).reorder(order) }

            subject(:sql) { order.apply_cursor_conditions(scope).to_sql }

            it 'has correct projections' do
              is_expected.to include('SELECT "projects"."id", "projects"."namespace_id", "projects"."created_at" AS created_at_field FROM "projects"')
            end
          end
        end
      end

      context 'when the cursor attribute is an array' do
        let(:model) { Group.new(traversal_ids: [1, 2]) }
        let(:scope) { Group.order(traversal_ids: :asc) }
        let(:order) do
          described_class.build(
            [
              Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
                attribute_name: 'traversal_ids',
                order_expression: Group.arel_table['traversal_ids'].asc,
                nullable: :not_nullable
              )
            ])
        end

        describe '#cursor_attributes_for_node' do
          subject { order.cursor_attributes_for_node(model) }

          it { is_expected.to eq({ traversal_ids: [1, 2] }.with_indifferent_access) }
        end

        describe '#apply_cursor_conditions' do
          subject(:sql) { order.apply_cursor_conditions(scope, { 'traversal_ids' => [1, 2] }).to_sql }

          it { is_expected.to include('"namespaces"."traversal_ids" > \'{1,2}\')') }
        end
      end
    end
  end

  describe 'UNION optimization' do
    let_it_be(:five_months_ago) { 5.months.ago }

    let_it_be(:user_1) { create(:user, created_at: five_months_ago) }
    let_it_be(:user_2) { create(:user, created_at: five_months_ago) }
    let_it_be(:user_3) { create(:user, created_at: 1.month.ago) }
    let_it_be(:user_4) { create(:user, created_at: 2.months.ago) }
    let_it_be(:ignored_column_model) do
      Class.new(ApplicationRecord) do
        self.table_name = 'users'

        include FromUnion

        ignore_column :username, remove_with: '16.4', remove_after: '2023-08-22'
      end
    end

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

      context 'when the scope model has ignored columns' do
        let(:ignored_expected_results) { expected_results.map { |r| r.becomes(ignored_column_model) } } # rubocop:disable Cop/AvoidBecomes

        context 'when scope selects all columns' do
          let(:scope) { ignored_column_model.order(created_at: :desc, id: :desc) }

          it 'returns items in the correct order' do
            expect(items).to eq(ignored_expected_results)
          end
        end

        context 'when scope selects only specific columns' do
          let(:scope) { ignored_column_model.order(created_at: :desc, id: :desc).select(:id, :created_at) }

          it 'returns items in the correct order' do
            expect(items).to eq(ignored_expected_results)
          end
        end
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
        order = described_class.extract_keyset_order_object(keyset_aware_scope)

        query = order.apply_cursor_conditions(scope, cursor_attributes, use_union_optimization: true).to_sql
        expect(query).to include('UNION ALL')
      end
    end
  end

  describe '#attribute_names' do
    let(:expected_attribute_names) { %w[id name] }
    let(:order) do
      described_class.build(
        [
          Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
            attribute_name: 'id',
            order_expression: Project.arel_table['id'].desc,
            nullable: :not_nullable
          ),
          Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
            attribute_name: 'name',
            order_expression: Project.arel_table['name'].desc,
            nullable: :not_nullable
          )
        ])
    end

    subject { order.attribute_names }

    it { is_expected.to match_array(expected_attribute_names) }
  end
end
