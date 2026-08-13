# frozen_string_literal: true

module ExceedQueryLimitHelpers
  class QueryDiff
    def initialize(expected, actual, show_common_queries)
      @expected = expected
      @actual = actual
      @show_common_queries = show_common_queries
    end

    def diff
      return combined_counts if @show_common_queries

      combined_counts
        .transform_values { select_suffixes_with_diffs(_1) }
        .reject { |_prefix, suffs| suffs.empty? }
    end

    private

    def select_suffixes_with_diffs(suffs)
      reject_groups_with_different_parameters(reject_suffixes_with_identical_counts(suffs))
    end

    def reject_suffixes_with_identical_counts(suffs)
      suffs.reject { |_k, counts| counts.first == counts.second }
    end

    # Eliminates groups that differ only in parameters,
    # to make it easier to debug the output.
    #
    # For example, if we have a group `SELECT * FROM users...`,
    # with the following suffixes
    #      `WHERE id = 1` (counts: N, 0)
    #      `WHERE id = 2` (counts: 0, N)
    def reject_groups_with_different_parameters(suffs)
      return suffs if suffs.size != 2

      counts_a, counts_b = suffs.values
      return {} if counts_a == counts_b.reverse && counts_a.include?(0)

      suffs
    end

    def expected_counts
      @expected.transform_values do |suffixes|
        suffixes.transform_values { |n| [n, 0] }
      end
    end

    def recorded_counts
      @actual.transform_values do |suffixes|
        suffixes.transform_values { |n| [0, n] }
      end
    end

    def combined_counts
      expected_counts.merge(recorded_counts) do |_k, exp, got|
        exp.merge(got) do |_k, exp_counts, got_counts|
          exp_counts.zip(got_counts).map { |a, b| a + b }
        end
      end
    end
  end

  SQL_ANNOTATION_REGEX = %r{\s*/\*.*\*/}

  DB_QUERY_RE = Regexp.union(
    [
      /^(?<prefix>SELECT .* FROM "?[a-z_]+"?) (?<suffix>.*)$/m,
      /^(?<prefix>UPDATE "?[a-z_]+"?) (?<suffix>.*)$/m,
      /^(?<prefix>INSERT INTO "[a-z_]+" \((?:"[a-z_]+",?\s?)+\)) (?<suffix>.*)$/m,
      /^(?<prefix>DELETE FROM "[a-z_]+") (?<suffix>.*)$/m
    ]
  ).freeze

  def with_threshold(threshold)
    @threshold = threshold
    self
  end

  def for_query(query)
    @query = query
    self
  end

  def for_model(model)
    table = model.table_name if model < ActiveRecord::Base
    for_query(/(FROM|UPDATE|INSERT INTO|DELETE FROM)\s+"#{table}"/)
  end

  def show_common_queries
    @show_common_queries = true
    self
  end

  def ignoring(pattern)
    @ignoring_pattern = pattern
    self
  end

  # Only use this for pre-existing specs. New specs must use consistent
  # `skip_cached` values between the compared query recorders.
  def allow_skip_cache_inconsistency
    @skip_cache_inconsistency_allowed = true
    self
  end

  def threshold
    @threshold.to_i
  end

  def expected_count
    if expected.is_a?(ActiveRecord::QueryRecorder)
      query_recorder_count(expected)
    else
      expected
    end
  end

  def actual_count
    @actual_count ||= query_recorder_count(recorder)
  end

  def query_recorder_count(query_recorder)
    verify_skip_cached_consistency!(query_recorder)

    return query_recorder.count unless @query || @ignoring_pattern

    query_log(query_recorder).size
  end

  def verify_skip_cached_consistency!(query_recorder)
    return if query_recorder.skip_cached == skip_cached

    @skip_cache_inconsistency_found = true
    return if @skip_cache_inconsistency_allowed

    raise ArgumentError, <<~MSG
      The `skip_cached` value of the compared query recorders does not match
      (the provided QueryRecorder was created with `skip_cached: #{query_recorder.skip_cached}`,
      while this matcher uses `skip_cached: #{skip_cached}`), which can lead to false positives.

      Create the QueryRecorder with `skip_cached: #{skip_cached}` to match this matcher, or use
      a matcher whose `skip_cached` value matches the recorder's.

      If this is a pre-existing spec that can't be fixed right away, chain
      `.allow_skip_cache_inconsistency` on the matcher to skip this check.
    MSG
  end

  def verify_no_unnecessary_inconsistency_allowance!
    return unless @skip_cache_inconsistency_allowed
    return if @skip_cache_inconsistency_found

    raise ArgumentError, <<~MSG
      `allow_skip_cache_inconsistency` is chained on this matcher, but the `skip_cached`
      values of the compared query recorders match. Remove the unnecessary
      `.allow_skip_cache_inconsistency` call.
    MSG
  end

  def query_log(query_recorder)
    filtered = query_recorder.log
    filtered = filtered.select { |q| q =~ @query } if @query
    filtered = filtered.reject { |q| q =~ @ignoring_pattern } if @ignoring_pattern
    filtered
  end

  def recorder
    @recorder ||= ActiveRecord::QueryRecorder.new(skip_cached: skip_cached, &@subject_block)
  end

  # Take a query recorder and tabulate the frequencies of suffixes for each prefix.
  #
  # @return Hash[String, Hash[String, Int]]
  #
  # Example:
  #
  # r = ActiveRecord::QueryRecorder.new do
  #   SomeTable.create(x: 1, y: 2, z: 3)
  #   SomeOtherTable.where(id: 1).first
  #   SomeTable.create(x: 4, y: 5, z: 6)
  #   SomeOtherTable.all
  # end
  # count_queries(r)
  # #=>
  #  {
  #    'INSERT INTO "some_table" VALUES' => {
  #      '(1,2,3)' => 1,
  #      '(4,5,6)' => 1
  #    },
  #    'SELECT * FROM "some_other_table"' => {
  #      'WHERE id = 1 LIMIT 1' => 1,
  #      '' => 2
  #    }
  #  }
  def count_queries(query_recorder)
    strip_sql_annotations(query_log(query_recorder))
      .map { |q| query_group_key(q) }
      .group_by { |k| k[:prefix] }
      .transform_values { |keys| frequencies(:suffix, keys) }
  end

  def frequencies(key, things)
    things.group_by { |x| x[key] }.transform_values(&:size)
  end

  def query_group_key(query)
    DB_QUERY_RE.match(query) || { prefix: query, suffix: '' }
  end

  def diff_query_counts(expected, actual)
    QueryDiff.new(expected, actual, @show_common_queries).diff
  end

  def diff_query_group_message(query, suffixes)
    suffix_messages = suffixes.map do |s, counts|
      "-- (expected: #{counts.first}, got: #{counts.second})\n   #{s}"
    end

    "#{query}...\n#{suffix_messages.join("\n")}"
  end

  def log_message
    if expected.is_a?(ActiveRecord::QueryRecorder)
      diff_counts = diff_query_counts(count_queries(expected), count_queries(@recorder))
      sections = diff_counts.filter_map { |q, suffixes| diff_query_group_message(q, suffixes) }

      <<~MSG
      Query Diff:
      -----------
      #{sections.join("\n\n")}
      MSG
    else
      query_log(@recorder).join("\n\n")
    end
  end

  def skip_cached
    true
  end

  def verify_count(&block)
    @subject_block = block
    result = actual_count > maximum
    # These matchers are used with `not_to`, so the spec passes when the
    # limit is not exceeded. Only check for an unnecessary allowance then,
    # so the error doesn't mask a genuine failure message.
    verify_no_unnecessary_inconsistency_allowance! unless result
    result
  end

  def maximum
    expected_count + threshold
  end

  def failure_message
    threshold_message = threshold > 0 ? " (+#{threshold})" : ''
    counts = "#{expected_count}#{threshold_message}"
    "Expected a maximum of #{counts} queries, got #{actual_count}:\n\n#{log_message}"
  end

  def strip_sql_annotations(logs)
    logs.map { |log| log.sub(SQL_ANNOTATION_REGEX, '') }
  end
end

RSpec::Matchers.define :issue_fewer_queries_than do
  supports_block_expectations

  include ExceedQueryLimitHelpers

  def control
    block_arg
  end

  def control_recorder
    @control_recorder ||= ActiveRecord::QueryRecorder.new(skip_cached: skip_cached, &control)
  end

  def expected_count
    control_recorder.count
  end

  def verify_count(&block)
    @subject_block = block

    # These blocks need to be evaluated in an expected order, in case
    # the events in expected affect the counts in actual
    expected_count
    actual_count

    result = actual_count < expected_count
    # Only check for an unnecessary allowance when the spec passes, so the
    # error doesn't mask a genuine failure message.
    verify_no_unnecessary_inconsistency_allowance! if result
    result
  end

  match do |block|
    verify_count(&block)
  end

  def failure_message
    <<~MSG
    Expected to issue fewer than #{expected_count} queries, but got #{actual_count}

    #{log_message}
    MSG
  end

  failure_message_when_negated do |actual|
    <<~MSG
    Expected query count of #{actual_count} to be less than #{expected_count}

    #{log_message}
    MSG
  end
end

RSpec::Matchers.define :issue_same_number_of_queries_as do |expected|
  supports_block_expectations

  include ExceedQueryLimitHelpers

  chain :or_fewer do
    @or_fewer = true
  end

  chain :ignoring_cached_queries do
    @skip_cached = true
  end

  def expected_count
    # Some tests pass a query recorder, others pass a block that executes an action.
    # Maybe, we need to clear the block usage and only accept query recorders.

    @expected_count ||= if expected.is_a?(ActiveRecord::QueryRecorder)
                          query_recorder_count(expected)
                        else
                          ActiveRecord::QueryRecorder.new(skip_cached: skip_cached, &block_arg).count
                        end
  end

  def verify_count(&block)
    @subject_block = block

    # These blocks need to be evaluated in an expected order, in case
    # the events in expected affect the counts in actual
    expected_count
    actual_count

    result = if @or_fewer
               actual_count <= expected_count
             else
               (expected_count - actual_count).abs <= threshold
             end

    # Only check for an unnecessary allowance when the spec passes, so the
    # error doesn't mask a genuine failure message.
    verify_no_unnecessary_inconsistency_allowance! if result
    result
  end

  match do |block|
    verify_count(&block)
  end

  def failure_message
    <<~MSG
    Expected #{expected_count_message} queries, but got #{actual_count}

    #{log_message}
    MSG
  end

  failure_message_when_negated do |actual|
    <<~MSG
    Expected #{actual_count} not to equal #{expected_count_message}

    #{log_message}
    MSG
  end

  def expected_count_message
    or_fewer_msg = "or fewer" if @or_fewer
    threshold_msg = "(+/- #{threshold})" unless threshold == 0

    [expected_count.to_s, or_fewer_msg, threshold_msg].compact.join(' ')
  end

  def skip_cached
    @skip_cached || false
  end
end

RSpec::Matchers.define :exceed_all_query_limit do |expected|
  supports_block_expectations

  include ExceedQueryLimitHelpers

  match do |block|
    if block.is_a?(ActiveRecord::QueryRecorder)
      @recorder = block
      verify_count
    else
      verify_count(&block)
    end
  end

  failure_message_when_negated do |actual|
    failure_message
  end

  def skip_cached
    false
  end
end

# Excludes cached methods from the query count
RSpec::Matchers.define :exceed_query_limit do |expected|
  supports_block_expectations

  include ExceedQueryLimitHelpers

  match do |block|
    if block.is_a?(ActiveRecord::QueryRecorder)
      @recorder = block
      verify_count
    else
      verify_count(&block)
    end
  end

  failure_message_when_negated do |actual|
    failure_message
  end
end

RSpec::Matchers.define :match_query_count do |expected|
  supports_block_expectations

  include ExceedQueryLimitHelpers

  chain :ignoring_cached_queries do
    @skip_cached = true
  end

  def verify_count(&block)
    @subject_block = block
    result = actual_count == maximum
    # Only check for an unnecessary allowance when the spec passes, so the
    # error doesn't mask a genuine failure message.
    verify_no_unnecessary_inconsistency_allowance! if result
    result
  end

  def failure_message
    threshold_message = threshold > 0 ? " (+#{threshold})" : ''
    counts = "#{expected_count}#{threshold_message}"
    "Expected exactly #{counts} queries, got #{actual_count}:\n\n#{log_message}"
  end

  def skip_cached
    @skip_cached || false
  end

  match do |block|
    verify_count(&block)
  end

  failure_message_when_negated do |actual|
    failure_message
  end
end
