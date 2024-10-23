# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Pagination::Keyset::InOperatorOptimization::QueryBuilder, feature_category: :database do
  let_it_be(:two_weeks_ago) { 2.weeks.ago }
  let_it_be(:three_weeks_ago) { 3.weeks.ago }
  let_it_be(:four_weeks_ago) { 4.weeks.ago }
  let_it_be(:five_weeks_ago) { 5.weeks.ago }

  let_it_be(:top_level_group) { create(:group) }
  let_it_be(:sub_group_1) { create(:group, parent: top_level_group) }
  let_it_be(:sub_group_2) { create(:group, parent: top_level_group) }
  let_it_be(:sub_sub_group_1) { create(:group, parent: sub_group_2) }

  let_it_be(:project_1) { create(:project, group: top_level_group) }
  let_it_be(:project_2) { create(:project, group: top_level_group) }

  let_it_be(:project_3) { create(:project, group: sub_group_1) }
  let_it_be(:project_4) { create(:project, group: sub_group_2) }

  let_it_be(:project_5) { create(:project, group: sub_sub_group_1) }

  let_it_be(:issues) do
    [
      create(:issue, project: project_1, created_at: three_weeks_ago, relative_position: 5),
      create(:issue, project: project_1, created_at: two_weeks_ago, relative_position: nil),
      create(:issue, project: project_2, created_at: two_weeks_ago, relative_position: 15),
      create(:issue, project: project_2, created_at: two_weeks_ago, relative_position: nil),
      create(:issue, project: project_3, created_at: four_weeks_ago, relative_position: nil),
      create(:issue, project: project_4, created_at: five_weeks_ago, relative_position: 10),
      create(:issue, project: project_5, created_at: four_weeks_ago, relative_position: nil)
    ]
  end

  let_it_be(:ignored_column_model) do
    Class.new(ApplicationRecord) do
      self.table_name = 'issues'

      ignore_column :title, remove_with: '16.4', remove_after: '2023-08-22'
    end
  end

  let(:scope_model) { Issue }
  let(:sql_type) { ->(model, column = 'id') { model.columns_hash[column].sql_type } }
  let(:created_records) { issues }
  let(:iterator) do
    Gitlab::Pagination::Keyset::Iterator.new(
      scope: scope.limit(batch_size),
      in_operator_optimization_options: in_operator_optimization_options
    )
  end

  shared_examples 'correct ordering examples' do |opts = {}|
    let(:all_records) do
      all_records = []
      iterator.each_batch(of: batch_size) do |records|
        all_records.concat(records)
      end
      all_records
    end

    unless opts[:skip_finder_query_test]
      it 'returns records in correct order' do
        expect(all_records).to eq(expected_order)
      end
    end

    context 'when not passing the finder query' do
      before do
        in_operator_optimization_options.delete(:finder_query)
      end

      it 'returns records in correct order' do
        expect(all_records).to eq(expected_order)
      end

      it 'loads only the order by column' do
        order_by_attribute_names = iterator
          .send(:order)
          .column_definitions
          .map(&:attribute_name)
          .map(&:to_s)

        record = all_records.first
        loaded_attributes = record.attributes.keys - ['time_estimate'] # time_estimate is always present (has default value)

        expect(loaded_attributes).to eq(order_by_attribute_names)
      end
    end
  end

  context 'when the scope model has ignored columns' do
    let(:scope) { ignored_column_model.order(id: :desc) }
    let(:expected_order) { ignored_column_model.where(id: issues.map(&:id)).sort_by(&:id).reverse }

    let(:in_operator_optimization_options) do
      {
        array_scope: Project.where(namespace_id: top_level_group.self_and_descendants.select(:id)).select(:id),
        array_mapping_scope: ->(id_expression) { ignored_column_model.where(ignored_column_model.arel_table[:project_id].eq(id_expression)) },
        finder_query: ->(id_expression) { ignored_column_model.where(ignored_column_model.arel_table[:id].eq(id_expression)) }
      }
    end

    context 'when iterating records one by one' do
      let(:batch_size) { 1 }

      it_behaves_like 'correct ordering examples'

      context 'when scope selects only some columns' do
        let(:scope) { ignored_column_model.order(id: :desc).select(:id) }

        it_behaves_like 'correct ordering examples'
      end
    end

    context 'when iterating records with LIMIT 3' do
      let(:batch_size) { 3 }

      it_behaves_like 'correct ordering examples'

      context 'when scope selects only some columns' do
        let(:scope) { ignored_column_model.order(id: :desc).select(:id) }

        it_behaves_like 'correct ordering examples'
      end
    end

    context 'when loading records at once' do
      let(:batch_size) { issues.size + 1 }

      it_behaves_like 'correct ordering examples'

      context 'when scope selects only some columns' do
        let(:scope) { ignored_column_model.order(id: :desc).select(:id) }

        it_behaves_like 'correct ordering examples'
      end
    end
  end

  context 'when ordering by issues.id DESC' do
    let(:scope) { Issue.order(id: :desc) }
    let(:expected_order) { issues.sort_by(&:id).reverse }

    let(:in_operator_optimization_options) do
      {
        array_scope: Project.where(namespace_id: top_level_group.self_and_descendants.select(:id)).select(:id),
        array_mapping_scope: ->(id_expression) { Issue.where(Issue.arel_table[:project_id].eq(id_expression)) },
        finder_query: ->(id_expression) { Issue.where(Issue.arel_table[:id].eq(id_expression)) }
      }
    end

    context 'when iterating records one by one' do
      let(:batch_size) { 1 }

      it_behaves_like 'correct ordering examples'
    end

    context 'when iterating records with LIMIT 3' do
      let(:batch_size) { 3 }

      it_behaves_like 'correct ordering examples'
    end

    context 'when loading records at once' do
      let(:batch_size) { issues.size + 1 }

      it_behaves_like 'correct ordering examples'
    end
  end

  context 'when ordering by issues.relative_position DESC NULLS LAST, id DESC' do
    let(:scope) { Issue.order(order) }
    let(:expected_order) { scope.to_a }

    let(:order) do
      # NULLS LAST ordering requires custom Order object for keyset pagination:
      # https://docs.gitlab.com/ee/development/database/keyset_pagination.html#complex-order-configuration
      Gitlab::Pagination::Keyset::Order.build(
        [
          Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
            attribute_name: :relative_position,
            column_expression: Issue.arel_table[:relative_position],
            order_expression: Issue.arel_table[:relative_position].desc.nulls_last,
            reversed_order_expression: Issue.arel_table[:relative_position].asc.nulls_first,
            order_direction: :desc,
            nullable: :nulls_last
          ),
          Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
            attribute_name: :id,
            order_expression: Issue.arel_table[:id].desc,
            nullable: :not_nullable
          )
        ])
    end

    let(:in_operator_optimization_options) do
      {
        array_scope: Project.where(namespace_id: top_level_group.self_and_descendants.select(:id)).select(:id),
        array_mapping_scope: ->(id_expression) { Issue.where(Issue.arel_table[:project_id].eq(id_expression)) },
        finder_query: ->(_relative_position_expression, id_expression) { Issue.where(Issue.arel_table[:id].eq(id_expression)) }
      }
    end

    context 'when iterating records one by one' do
      let(:batch_size) { 1 }

      it_behaves_like 'correct ordering examples'
    end

    context 'when iterating records with LIMIT 3' do
      let(:batch_size) { 3 }

      it_behaves_like 'correct ordering examples'
    end

    context 'with condition "relative_position IS NULL"' do
      let(:base_scope) { Issue.where(relative_position: nil) }
      let(:scope) { base_scope.order(order) }

      let(:in_operator_optimization_options) do
        {
          array_scope: Project.where(namespace_id: top_level_group.self_and_descendants.select(:id)).select(:id),
          array_mapping_scope: ->(id_expression) { Issue.merge(base_scope.dup).where(Issue.arel_table[:project_id].eq(id_expression)) },
          finder_query: ->(_relative_position_expression, id_expression) { Issue.where(Issue.arel_table[:id].eq(id_expression)) }
        }
      end

      context 'when iterating records one by one' do
        let(:batch_size) { 1 }

        it_behaves_like 'correct ordering examples'
      end

      context 'when iterating records with LIMIT 3' do
        let(:batch_size) { 3 }

        it_behaves_like 'correct ordering examples'
      end
    end
  end

  context 'when ordering by issues.created_at DESC, issues.id ASC' do
    let(:scope) { Issue.order(created_at: :desc, id: :asc) }
    let(:expected_order) { issues.sort_by { |issue| [issue.created_at.to_f * -1, issue.id] } }

    let(:in_operator_optimization_options) do
      {
        array_scope: Project.where(namespace_id: top_level_group.self_and_descendants.select(:id)).select(:id),
        array_mapping_scope: ->(id_expression) { Issue.where(Issue.arel_table[:project_id].eq(id_expression)) },
        finder_query: ->(_created_at_expression, id_expression) { Issue.where(Issue.arel_table[:id].eq(id_expression)) }
      }
    end

    context 'when iterating records one by one' do
      let(:batch_size) { 1 }

      it_behaves_like 'correct ordering examples'
    end

    context 'when iterating records with LIMIT 3' do
      let(:batch_size) { 3 }

      it_behaves_like 'correct ordering examples'
    end

    context 'when loading records at once' do
      let(:batch_size) { issues.size + 1 }

      it_behaves_like 'correct ordering examples'
    end
  end

  context 'pagination support' do
    let(:scope) { Issue.order(id: :desc) }
    let(:expected_order) { issues.sort_by(&:id).reverse }

    let(:options) do
      {
        scope: scope,
        array_scope: Project.where(namespace_id: top_level_group.self_and_descendants.select(:id)).select(:id),
        array_mapping_scope: ->(id_expression) { Issue.where(Issue.arel_table[:project_id].eq(id_expression)) },
        finder_query: ->(id_expression) { Issue.where(Issue.arel_table[:id].eq(id_expression)) }
      }
    end

    context 'offset pagination' do
      subject(:optimized_scope) { described_class.new(**options).execute }

      it 'paginates the scopes' do
        first_page = optimized_scope.page(1).per(2)
        expect(first_page).to eq(expected_order[0...2])

        second_page = optimized_scope.page(2).per(2)
        expect(second_page).to eq(expected_order[2...4])

        third_page = optimized_scope.page(3).per(2)
        expect(third_page).to eq(expected_order[4...6])
      end
    end

    context 'keyset pagination' do
      def paginator(cursor = nil)
        scope.keyset_paginate(cursor: cursor, per_page: 2, keyset_order_options: options)
      end

      it 'paginates correctly' do
        first_page = paginator.records
        expect(first_page).to eq(expected_order[0...2])

        cursor_for_page_2 = paginator.cursor_for_next_page

        second_page = paginator(cursor_for_page_2).records
        expect(second_page).to eq(expected_order[2...4])

        cursor_for_page_3 = paginator(cursor_for_page_2).cursor_for_next_page

        third_page = paginator(cursor_for_page_3).records
        expect(third_page).to eq(expected_order[4...6])
      end
    end
  end

  it 'raises error when unsupported scope is passed' do
    scope = Issue.order(Arel::Nodes::NamedFunction.new('UPPER', [Issue.arel_table[:id]]))

    options = {
      scope: scope,
      array_scope: Project.where(namespace_id: top_level_group.self_and_descendants.select(:id)).select(:id),
      array_mapping_scope: ->(id_expression) { Issue.where(Issue.arel_table[:project_id].eq(id_expression)) },
      finder_query: ->(id_expression) { Issue.where(Issue.arel_table[:id].eq(id_expression)) }
    }

    expect { described_class.new(**options).execute }.to raise_error(/The order on the scope does not support keyset pagination/)
  end

  context 'when ordering by SQL expression' do
    let(:order) do
      # ORDER BY (id * 10), id
      Gitlab::Pagination::Keyset::Order.build(
        [
          Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
            attribute_name: 'id_multiplied_by_ten',
            order_expression: Arel.sql('(id * 10)').asc,
            sql_type: sql_type.call(Issue)
          ),
          Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
            attribute_name: :id,
            order_expression: Issue.arel_table[:id].asc
          )
        ])
    end

    let(:scope) { Issue.reorder(order) }
    let(:expected_order) { issues.sort_by(&:id) }

    let(:in_operator_optimization_options) do
      {
        array_scope: Project.where(namespace_id: top_level_group.self_and_descendants.select(:id)).select(:id),
        array_mapping_scope: ->(id_expression) { Issue.where(Issue.arel_table[:project_id].eq(id_expression)) }
      }
    end

    context 'when iterating records one by one' do
      let(:batch_size) { 1 }

      it_behaves_like 'correct ordering examples', skip_finder_query_test: true
    end

    context 'when iterating records with LIMIT 3' do
      let(:batch_size) { 3 }

      it_behaves_like 'correct ordering examples', skip_finder_query_test: true
    end

    context 'when passing finder query' do
      let(:batch_size) { 3 }

      it 'raises error, loading complete rows are not supported with SQL expressions' do
        in_operator_optimization_options[:finder_query] = ->(_, _) { Issue.select(:id, '(id * 10)').where(id: -1) }

        expect(in_operator_optimization_options[:finder_query]).not_to receive(:call)

        expect do
          iterator.each_batch(of: batch_size) { |records| records.to_a }
        end.to raise_error(/The "RecordLoaderStrategy" does not support/)
      end
    end
  end

  context 'when ordering by JOIN-ed columns' do
    let(:scope) { cte_with_issues_and_projects.apply_to(Issue.where({}).select(Arel.star)).reorder(order) }

    let(:cte_with_issues_and_projects) do
      cte_query = Issue.select('issues.id AS id', 'project_id', 'projects.id AS projects_id', 'projects.name AS projects_name').joins(:project)
      Gitlab::SQL::CTE.new(:issue_with_project, cte_query, materialized: false)
    end

    let(:in_operator_optimization_options) do
      {
        array_scope: Project.where(namespace_id: top_level_group.self_and_descendants.select(:id)).select(:id),
        array_mapping_scope: ->(id_expression) { Issue.where(Issue.arel_table[:project_id].eq(id_expression)) }
      }
    end

    context 'when directions are project.id DESC, issues.id ASC' do
      let(:order) do
        Gitlab::Pagination::Keyset::Order.build([
          Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
            attribute_name: 'projects_id',
            order_expression: Issue.arel_table[:projects_id].asc,
            sql_type: sql_type.call(Project),
            nullable: :not_nullable
          ),
          Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
            attribute_name: :id,
            order_expression: Issue.arel_table[:id].asc
          )
        ])
      end

      let(:expected_order) { issues.sort_by { |issue| [issue.project_id, issue.id] } }

      context 'when iterating records one by one' do
        let(:batch_size) { 1 }

        it_behaves_like 'correct ordering examples', skip_finder_query_test: true
      end

      context 'when iterating records with LIMIT 2' do
        let(:batch_size) { 2 }

        it_behaves_like 'correct ordering examples', skip_finder_query_test: true
      end
    end

    context 'when directions are projects.id DESC, issues.id ASC' do
      let(:order) do
        Gitlab::Pagination::Keyset::Order.build([
          Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
            attribute_name: 'projects_id',
            order_expression: Issue.arel_table[:projects_id].desc,
            sql_type: sql_type.call(Project),
            nullable: :not_nullable
          ),
          Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
            attribute_name: :id,
            order_expression: Issue.arel_table[:id].asc
          )
        ])
      end

      let(:expected_order) { issues.sort_by { |issue| [issue.project_id * -1, issue.id] } }

      context 'when iterating records one by one' do
        let(:batch_size) { 1 }

        it_behaves_like 'correct ordering examples', skip_finder_query_test: true
      end

      context 'when iterating records with LIMIT 2' do
        let(:batch_size) { 2 }

        it_behaves_like 'correct ordering examples', skip_finder_query_test: true
      end
    end

    context 'when directions are projects.name ASC, projects.id ASC, issues.id ASC' do
      let(:order) do
        Gitlab::Pagination::Keyset::Order.build([
          Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
            attribute_name: 'projects_name',
            order_expression: Issue.arel_table[:projects_name].asc,
            sql_type: sql_type.call(Project, 'name'),
            nullable: :not_nullable
          ),
                                                  Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
                                                    attribute_name: 'projects_id',
                                                    order_expression: Issue.arel_table[:projects_id].asc,
                                                    sql_type: sql_type.call(Project),
                                                    nullable: :not_nullable
                                                  ),
                                                  Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
                                                    attribute_name: :id,
                                                    order_expression: Issue.arel_table[:id].asc
                                                  )
        ])
      end

      let(:expected_order) { issues.sort_by { |issue| [issue.project.name, issue.project.id, issue.id] } }

      context 'when iterating records with LIMIT 2' do
        let(:batch_size) { 2 }

        it_behaves_like 'correct ordering examples', skip_finder_query_test: true
      end
    end

    context 'when directions are projects.name ASC (nullable), issues.id ASC' do
      let(:cte_with_issues_and_projects) do
        cte_query = Issue.select('issues.id AS id', 'project_id', 'projects.id AS projects_id', 'NULL AS projects_name').joins(:project)
        Gitlab::SQL::CTE.new(:issue_with_project, cte_query, materialized: false)
      end

      let(:order) do
        Gitlab::Pagination::Keyset::Order.build([
          Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
            attribute_name: 'projects_name',
            order_expression: Issue.arel_table[:projects_name].asc,
            sql_type: sql_type.call(Project, 'name'),
            nullable: :nulls_last
          ),
                                                  Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
                                                    attribute_name: :id,
                                                    order_expression: Issue.arel_table[:id].asc
                                                  )
        ])
      end

      let(:expected_order) { issues.sort_by { |issue| [issue.id] } }

      context 'when iterating records with LIMIT 2' do
        let(:batch_size) { 2 }

        it_behaves_like 'correct ordering examples', skip_finder_query_test: true
      end
    end
  end
end
