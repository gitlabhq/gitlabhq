# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::QueryAnalyzers::PreventSetOperatorMismatch::SelectStmt, feature_category: :cell do
  include PreventSetOperatorMismatchHelper

  let_it_be(:static_namespace_columns) { Namespace.column_names.join(', ') }

  let(:node) { sql_select_node(sql) }

  subject { described_class.new(node).types }

  shared_examples 'valid SQL' do
    it { is_expected.not_to include(Type::INVALID) }
  end

  shared_examples 'invalid SQL' do
    it { is_expected.to include(Type::INVALID) }
  end

  shared_context 'with basic set operator queries' do
    let(:set_operator_queries) do
      {
        'set operator with static columns' => <<-SQL,
          SELECT id, name FROM namespaces WHERE name = 'test1'
          #{set_operator}
          SELECT id, name FROM namespaces WHERE name = 'test2'
        SQL
        'set operator with static referenced columns' => <<-SQL,
          SELECT namespaces.id, name FROM namespaces WHERE name = 'test1'
          #{set_operator}
          SELECT id, namespaces.name FROM namespaces WHERE name = 'test2'
        SQL
        'set operator with static alias referenced columns' => <<-SQL,
          SELECT namespaces.id, name FROM namespaces WHERE name = 'test1'
          #{set_operator}
          SELECT id, namespaces2.name FROM namespaces2 WHERE name = 'test2'
        SQL
        'set operator with dynamic columns' => <<-SQL,
          SELECT * FROM namespaces WHERE name = 'test1'
          #{set_operator}
          SELECT * FROM namespaces WHERE name = 'test2'
        SQL
        'set operator with dynamic referenced columns' => <<-SQL,
          SELECT namespaces.* FROM namespaces WHERE name = 'test1'
          #{set_operator}
          SELECT namespaces.* FROM namespaces WHERE name = 'test2'
        SQL
        'set operator with dynamic referenced aliased columns' => <<-SQL,
          SELECT namespaces.* FROM namespaces WHERE name = 'test1'
          #{set_operator}
          SELECT namespaces2.* FROM namespaces namespaces2 WHERE name = 'test2'
        SQL
        'set operator with dynamic columns without using star' => <<-SQL,
          SELECT namespaces FROM namespaces WHERE name = 'test1'
          #{set_operator}
          SELECT * FROM namespaces WHERE name = 'test2'
        SQL
        'set operator with single dynamic referenced columns' => <<-SQL,
          SELECT namespaces.* FROM namespaces WHERE name = 'test1'
          #{set_operator}
          SELECT * FROM namespaces WHERE name = 'test2'
        SQL
        'set operator with static and dynamic columns' => <<-SQL,
          SELECT #{static_namespace_columns} FROM namespaces WHERE name = 'test1'
          #{set_operator}
          SELECT * FROM namespaces WHERE name = 'test2'
        SQL
        'set operator with static aliased columns and dynamic columns' => <<-SQL,
          SELECT #{Namespace.column_names.map { |c| "namespaces2.#{c}" }.join(', ')}
          FROM namespaces namespaces2
          WHERE name = 'test1'
          #{set_operator}
          SELECT * FROM namespaces WHERE name = 'test2'
        SQL
        'set operator with static columns and dynamic aliased columns' => <<-SQL,
          SELECT #{static_namespace_columns} FROM namespaces WHERE name = 'test1'
          #{set_operator}
          SELECT namespaces2.* FROM namespaces namespaces2 WHERE name = 'test2'
        SQL
        'set operator with static and dynamic aliased columns' => <<-SQL,
          SELECT #{Namespace.column_names.map { |c| "namespaces2.#{c}" }.join(', ')}
          FROM namespaces namespaces2
          WHERE name = 'test1'
          #{set_operator}
          SELECT namespaces3.* FROM namespaces namespaces3 WHERE name = 'test2'
        SQL
        'set operator with mixed dynamic and static columns' => <<-SQL,
          SELECT namespaces.*, projects.id FROM namespaces, projects WHERE name = 'test1'
          #{set_operator}
          SELECT namespaces.*, projects.id FROM namespaces, projects WHERE name = 'test2'
        SQL
        'set operator without references' => <<-SQL
          SELECT 1
          #{set_operator}
          SELECT 2
        SQL
      }
    end

    where(:query_name, :behavior) do
      [
        ['set operator with static columns',  'valid SQL'],
        ['set operator with static referenced columns', 'valid SQL'],
        ['set operator with static alias referenced columns', 'valid SQL'],
        ['set operator with dynamic columns', 'valid SQL'],
        ['set operator with dynamic referenced columns', 'valid SQL'],
        ['set operator with dynamic referenced aliased columns', 'valid SQL'],
        ['set operator with dynamic columns without using star', 'invalid SQL'],
        ['set operator with single dynamic referenced columns', 'valid SQL'],
        ['set operator with static and dynamic columns', 'invalid SQL'],
        ['set operator with static and dynamic aliased columns', 'invalid SQL'],
        ['set operator with static aliased columns and dynamic columns', 'invalid SQL'],
        ['set operator with static columns and dynamic aliased columns', 'invalid SQL'],
        ['set operator with static and dynamic aliased columns', 'invalid SQL'],
        ['set operator with mixed dynamic and static columns', 'valid SQL'],
        ['set operator without references', 'valid SQL']
      ]
    end
  end

  %w[UNION INTERSECT EXCEPT].each do |set_operator|
    context "with #{set_operator}" do
      let(:set_operator) { set_operator }

      context "for basic #{set_operator} queries" do
        include_context 'with basic set operator queries'

        with_them do
          let(:sql) { set_operator_queries[query_name] }

          it_behaves_like params[:behavior]
        end
      end

      context 'for subquery' do
        context "with #{set_operator}" do
          where(:select_columns) do
            [
              ['*'],
              ['sub.*'],
              ['sub'],
              ['sub.id']
            ]
          end

          with_them do
            include_context 'with basic set operator queries'

            with_them do
              let(:sql) do
                <<-SQL
                  SELECT #{select_columns}
                  FROM (
                    #{set_operator_queries[query_name]}
                  ) sub
                SQL
              end

              it_behaves_like params[:behavior]
            end
          end
        end

        context "when used by one side of #{set_operator}" do
          let(:sql) do
            <<-SQL
              SELECT #{union1}
              FROM (
                SELECT #{subquery}
                FROM namespaces
              ) namespaces

              #{set_operator}

              SELECT #{union2}
              FROM namespaces
            SQL
          end

          where(:union1, :union2, :subquery, :expected) do
            [
              ['*', '*', '*', 'valid SQL'],
              [ref(:static_namespace_columns), '*', '*', 'invalid SQL'],
              ['*', ref(:static_namespace_columns), '*', 'invalid SQL'],
              ['*', '*', ref(:static_namespace_columns), 'invalid SQL'],
              [ref(:static_namespace_columns), ref(:static_namespace_columns), '*', 'valid SQL'],
              [ref(:static_namespace_columns), '*', ref(:static_namespace_columns), 'invalid SQL'],
              ['*', ref(:static_namespace_columns), ref(:static_namespace_columns), 'valid SQL'],
              ['namespaces', 'namespaces', 'namespaces', 'valid SQL'],
              # Used by our keyset pagination queries.
              ['NULL :: namespaces', 'namespaces', 'id, name', 'valid SQL'],
              ['NULL :: namespaces, id, name', 'namespaces, id, name', 'namespaces', 'valid SQL']
            ]
          end

          with_them do
            it_behaves_like params[:expected]
          end
        end
      end

      context 'for CTE' do
        context "when #{set_operator}" do
          where(:select_columns) do
            [
              ['*'],
              ['namespaces_cte.*'],
              ['namespaces_cte.id']
            ]
          end

          with_them do
            include_context 'with basic set operator queries'

            with_them do
              let(:sql) do
                <<-SQL
                  WITH namespaces_cte AS (
                    #{set_operator_queries[query_name]}
                  )
                  SELECT *
                  FROM namespaces_cte
                SQL
              end

              it_behaves_like params[:behavior]
            end
          end
        end

        context "when used by one side of #{set_operator}" do
          let(:sql) do
            <<-SQL
              WITH #{cte_name} AS (
                SELECT #{cte_select_columns}
                FROM namespaces
              )
              SELECT #{select_columns}
              FROM #{cte_name}

              #{set_operator}

              SELECT *
              FROM namespaces
            SQL
          end

          where(:cte_select_columns, :select_columns, :cte_name, :expected) do
            [
              ['*', '*', 'some_cte', 'valid SQL'],
              [ref(:static_namespace_columns), '*', 'some_cte', 'invalid SQL'],
              ['*', ref(:static_namespace_columns), 'some_cte', 'invalid SQL'],
              [ref(:static_namespace_columns), ref(:static_namespace_columns), 'some_cte', 'invalid SQL'],
              ['*', '*', 'some_cte', 'valid SQL'],
              # Same scenarios as above, but the CTE name matches the table name in the CTE.
              ['*', '*', 'namespaces', 'valid SQL'],
              [ref(:static_namespace_columns), '*', 'namespaces', 'valid SQL'],
              ['*', ref(:static_namespace_columns), 'namespaces', 'invalid SQL'],
              [ref(:static_namespace_columns), ref(:static_namespace_columns), 'namespaces', 'valid SQL'],
              ['*', '*', 'namespaces', 'valid SQL']
            ]
          end

          with_them do
            it_behaves_like params[:expected]
          end
        end

        context 'when recursive' do
          let(:sql) do
            <<-SQL
              WITH RECURSIVE namespaces_cte AS (
                (
                  SELECT #{select1}
                  FROM namespaces
                )
                UNION
                (
                  SELECT #{select2}
                  FROM namespaces_cte
                )
              )
              SELECT *
              FROM namespaces_cte
            SQL
          end

          where(:select1, :select2, :expected) do
            [
              ['id', 'id', 'valid SQL'],
              [ref(:static_namespace_columns), '*', 'valid SQL'],
              ['*', ref(:static_namespace_columns), 'invalid SQL']
            ]
          end

          with_them do
            it_behaves_like params[:expected]
          end
        end
      end

      context 'for subselect' do
        context 'with set operator' do
          let(:sql) do
            <<-SQL
              SELECT (
                SELECT id FROM namespaces
                #{set_operator}
                SELECT id FROM namespaces
              ) AS namespace_id
            SQL
          end

          it_behaves_like 'valid SQL'
        end
      end
    end
  end

  context 'with lateral join' do
    let(:sql) do
      <<-SQL
      SELECT namespaces.id
      FROM
        namespaces CROSS
        JOIN LATERAL (
          SELECT
            namespaces.traversal_ids[array_length(namespaces.traversal_ids, 1) ] AS id
          FROM
            namespaces
          WHERE
            namespaces.type = 'Group'
            AND namespaces.traversal_ids @ > ARRAY[members.source_id]
        ) namespaces
      SQL
    end

    pending
  end

  context 'when columns are not referenced' do
    let(:sql) do
      <<-SQL
        SELECT
          COUNT(1)
        FROM (
          SELECT #{static_namespace_columns}
          FROM namespaces
          UNION
          SELECT *
          FROM namespaces
        ) invalid_union
      SQL
    end

    # Error will bubble up even though the parent query does not reference any of the sub-query columns.
    it_behaves_like 'invalid SQL'
  end
end
