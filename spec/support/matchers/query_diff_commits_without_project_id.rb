# frozen_string_literal: true

# After the `merge_request_diff_commits_b5377a7a34` -> `merge_request_diff_commits`
# table swap, `merge_request_diff_commits` will be partitioned by `project_id`.
# Any SELECT that touches the table without a table-qualified `project_id` filter
# will cause a full cross-partition scan instead of pruning to a single partition.
#
# This matcher records queries inside a block and asserts on their `project_id` filter
# coverage. It distinguishes three states:
#
#   1. No SELECT on the table was captured at all (memoisation, wrong code path, etc.)
#   2. SELECTs were captured and at least one lacks a table-qualified `project_id` filter
#   3. SELECTs were captured and all have a table-qualified `project_id` filter
#
# `not_to` (state 3 expected): fails for both state 1 (vacuous pass guard) and state 2.
# `to`     (state 2 expected): fails for both state 1 (nothing captured) and state 3.
#
# Example:
#
#   expect { diff.commit_shas }.not_to query_diff_commits_without_project_id
#   expect { diff.commit_shas }.to     query_diff_commits_without_project_id
#
module DiffCommitsProjectIdPruningMatcher
  TABLE = 'merge_request_diff_commits'

  module_function

  def select_queries_on_table(queries)
    queries
      .select { |q| select_query?(q) }
      .select { |q| references_table?(q) }
  end

  def offending_queries(table_queries)
    table_queries.reject { |q| has_table_qualified_project_id?(q) }
  end

  def select_query?(query)
    query.match?(/\A\s*(SELECT|WITH)\b/i)
  end

  def references_table?(query)
    query.include?(TABLE)
  end

  # Matches "merge_request_diff_commits"."project_id" or merge_request_diff_commits.project_id
  def has_table_qualified_project_id?(query)
    query.match?(/\b#{TABLE}"?\s*\.\s*"?project_id\b/io)
  end
end

RSpec::Matchers.define :query_diff_commits_without_project_id do
  supports_block_expectations

  # Shared setup used by both match directions.
  def record_queries(block)
    @recorder = ActiveRecord::QueryRecorder.new(&block)
    @table_queries = DiffCommitsProjectIdPruningMatcher.select_queries_on_table(@recorder.log)
    @offending = DiffCommitsProjectIdPruningMatcher.offending_queries(@table_queries)
  end

  # `to`: passes when at least one SELECT on the table lacks the project_id filter.
  match do |block|
    record_queries(block)
    @offending.any?
  end

  # `not_to`: passes only when SELECTs were captured AND all have the project_id filter.
  # Explicitly fails when no queries touched the table to prevent vacuous passes caused
  # by memoisation or code-path changes.
  define_method(:does_not_match?) do |block|
    record_queries(block)
    @table_queries.any? && @offending.none?
  end

  failure_message do
    if @table_queries.none?
      "no SELECT on `#{DiffCommitsProjectIdPruningMatcher::TABLE}` was captured in the block — " \
        "the code path may not be querying the table, or results are memoised from a prior call"
    else
      "expected at least one SELECT on `#{DiffCommitsProjectIdPruningMatcher::TABLE}` without " \
        "a table-qualified `project_id` filter, but all #{@table_queries.size} " \
        "#{'query'.pluralize(@table_queries.size)} had one"
    end
  end

  failure_message_when_negated do
    if @table_queries.none?
      "no SELECT on `#{DiffCommitsProjectIdPruningMatcher::TABLE}` was captured in the block — " \
        "the assertion would pass vacuously; ensure the code path actually queries the table " \
        "(results may be memoised from a prior call)"
    else
      "expected all SELECTs on `#{DiffCommitsProjectIdPruningMatcher::TABLE}` to include " \
        "a table-qualified `project_id` filter (for partition pruning after the table swap), " \
        "but the following did not:\n\n#{@offending.join("\n\n")}"
    end
  end
end
