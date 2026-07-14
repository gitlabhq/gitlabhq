# frozen_string_literal: true

# After the `merge_request_diff_commits_b5377a7a34` -> `merge_request_diff_commits`
# table swap, the new table only has 4 columns:
#   merge_request_commits_metadata_id, merge_request_diff_id, project_id, relative_order.
#
# Several columns present on the current `merge_request_diff_commits` table
# (sha, message, authored_date, committed_date, commit_author_id, committer_id, trailers)
# are absent from the new partitioned table. Any SQL that still references them on
# `merge_request_diff_commits` will raise PG::UndefinedColumn after the swap.
#
# This matcher records queries inside the block and fails if any of them reference
# one of those columns on `merge_request_diff_commits`. Use it on code paths that
# the `mr_diff_commits_read_new_table` feature flag is meant to route away from the
# old columns.
#
# Example:
#
#   expect { merge_request_diff.includes_any_commits?(['abc']) }
#     .not_to query_missing_diff_commit_columns
#
module MissingDiffCommitColumnsMatcher
  # Columns present on the current `merge_request_diff_commits` table but absent
  # from the new partitioned table that will replace it.
  COLUMNS_ABSENT_FROM_NEW_TABLE = %w[
    sha
    message
    authored_date
    committed_date
    commit_author_id
    committer_id
    trailers
  ].freeze

  TABLE = 'merge_request_diff_commits'

  module_function

  def offending_queries(queries)
    queries.select { |query| references_missing_column?(query) }
  end

  def references_missing_column?(query)
    COLUMNS_ABSENT_FROM_NEW_TABLE.any? { |column| query.match?(pattern_for(column)) }
  end

  # Matches `merge_request_diff_commits.<col>` and `"merge_request_diff_commits"."<col>"`
  # (with or without optional quoting/whitespace).
  def pattern_for(column)
    /\b#{TABLE}"?\.\s*"?#{column}\b/
  end
end

RSpec::Matchers.define :query_missing_diff_commit_columns do
  supports_block_expectations

  match do |block|
    @recorder = ActiveRecord::QueryRecorder.new(&block)
    @offending = MissingDiffCommitColumnsMatcher.offending_queries(@recorder.log)
    @offending.any?
  end

  failure_message do
    "expected at least one query to reference a column absent from the new diff commits table " \
      "(#{MissingDiffCommitColumnsMatcher::COLUMNS_ABSENT_FROM_NEW_TABLE.join(', ')}) " \
      "on `#{MissingDiffCommitColumnsMatcher::TABLE}`, but none did."
  end

  failure_message_when_negated do
    "expected no query to reference columns absent from the new diff commits table " \
      "(#{MissingDiffCommitColumnsMatcher::COLUMNS_ABSENT_FROM_NEW_TABLE.join(', ')}) " \
      "on `#{MissingDiffCommitColumnsMatcher::TABLE}`, but the following queries did:\n\n" \
      "#{@offending.join("\n\n")}"
  end
end
