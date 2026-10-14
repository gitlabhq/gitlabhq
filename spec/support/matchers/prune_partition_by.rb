# frozen_string_literal: true

# Asserts that every SELECT captured in the block which touches BOTH partitioned
# tables constrains them via `table1.col1 = table2.col2` so Postgres can prune
# to a single partition.
#
# A SELECT is a "candidate" only when it references both tables. Single-table
# SELECTs are out of scope for this matcher (test with a different matcher if
# needed).
#
# Three states are distinguished:
#   1. No candidate SELECT captured (vacuous): both `to` and `not_to` fail.
#   2. All candidates covered: `to` passes, `not_to` fails.
#   3. At least one candidate uncovered: `to` fails, `not_to` passes.
#
# Example:
#   expect { worker.jobs.to_a }.to prune_partition_by(
#     'background_operation_jobs',    'worker_partition',
#     'background_operation_workers', 'partition'
#   )
#
# Known limitations:
#   - Aliased table references (e.g. "background_operation_jobs" "boj") are not
#     resolved; the matcher only recognises predicates that qualify by the full
#     table name.
#   - Inspects SQL text, not the planner. For list/hash-partitioned tables with
#     equality predicates this is equivalent in practice.
module PrunePartitionByMatcher
  module_function

  def select_query?(query)
    query.match?(/\A[\s(]*(SELECT|WITH)\b/i)
  end

  def references_table?(query, table)
    query.match?(/"?#{Regexp.escape(table)}"?/i)
  end

  # Matches `table1.col1 = table2.col2` in either order (with or without quotes).
  def column_equality_regex(table1, col1, table2, col2)
    lhs = %("?#{Regexp.escape(table1)}"?\\s*\\.\\s*"?#{Regexp.escape(col1)}"?)
    rhs = %("?#{Regexp.escape(table2)}"?\\s*\\.\\s*"?#{Regexp.escape(col2)}"?)
    Regexp.new("(?:#{lhs}\\s*=\\s*#{rhs})|(?:#{rhs}\\s*=\\s*#{lhs})", Regexp::IGNORECASE)
  end

  def covered?(query, table1, col1, table2, col2)
    query.match?(column_equality_regex(table1, col1, table2, col2))
  end

  def candidate_queries(queries, table1, table2)
    queries
      .select { |q| select_query?(q) }
      .select { |q| references_table?(q, table1) && references_table?(q, table2) }
  end

  def uncovered_queries(candidates, table1, col1, table2, col2)
    candidates.reject { |q| covered?(q, table1, col1, table2, col2) }
  end
end

RSpec::Matchers.define :prune_partition_by do |table1, col1, table2, col2|
  supports_block_expectations

  def record_queries(block, table1, col1, table2, col2)
    @recorder = ActiveRecord::QueryRecorder.new(&block)
    @candidates = PrunePartitionByMatcher.candidate_queries(@recorder.log, table1, table2)
    @uncovered = PrunePartitionByMatcher.uncovered_queries(@candidates, table1, col1, table2, col2)
  end

  # `to`: passes when candidates exist AND all are covered (invariant holds).
  match do |block|
    record_queries(block, table1, col1, table2, col2)
    @candidates.any? && @uncovered.none?
  end

  # `not_to`: passes when candidates exist AND at least one is uncovered
  # (invariant is broken). Still fails on no candidates to prevent vacuous passes.
  define_method(:does_not_match?) do |block|
    record_queries(block, table1, col1, table2, col2)
    @candidates.any? && @uncovered.any?
  end

  failure_message do
    if @candidates.none?
      "no SELECT touching both `#{table1}` and `#{table2}` was captured in the block — " \
        "the code path may not join the tables, or results are memoised from a prior call"
    else
      "expected every SELECT touching both `#{table1}` and `#{table2}` to constrain " \
        "`#{table1}.#{col1} = #{table2}.#{col2}`, but the following did not:\n\n#{@uncovered.join("\n\n")}"
    end
  end

  failure_message_when_negated do
    if @candidates.none?
      "no SELECT touching both `#{table1}` and `#{table2}` was captured in the block — " \
        "the assertion would pass vacuously; ensure the code path actually joins the tables " \
        "(results may be memoised from a prior call)"
    else
      "expected at least one SELECT touching both `#{table1}` and `#{table2}` to be missing " \
        "the partition predicate `#{table1}.#{col1} = #{table2}.#{col2}`, but all " \
        "#{@candidates.size} candidate #{'query'.pluralize(@candidates.size)} had it"
    end
  end
end
