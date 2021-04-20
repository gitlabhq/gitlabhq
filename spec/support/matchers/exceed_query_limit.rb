# frozen_string_literal: true

module ExceedQueryLimitHelpers
  MARGINALIA_ANNOTATION_REGEX = %r{\s*\/\*.*\*\/}.freeze

  DB_QUERY_RE = Regexp.union([
    /^(?<prefix>SELECT .* FROM "?[a-z_]+"?) (?<suffix>.*)$/m,
    /^(?<prefix>UPDATE "?[a-z_]+"?) (?<suffix>.*)$/m,
    /^(?<prefix>INSERT INTO "[a-z_]+" \((?:"[a-z_]+",?\s?)+\)) (?<suffix>.*)$/m,
    /^(?<prefix>DELETE FROM "[a-z_]+") (?<suffix>.*)$/m
  ]).freeze

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
    return query_recorder.count unless @query || @ignoring_pattern

    query_log(query_recorder).size
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
    strip_marginalia_annotations(query_log(query_recorder))
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
    expected_counts = expected.transform_values do |suffixes|
      suffixes.transform_values { |n| [n, 0] }
    end
    recorded_counts = actual.transform_values do |suffixes|
      suffixes.transform_values { |n| [0, n] }
    end

    combined_counts = expected_counts.merge(recorded_counts) do |_k, exp, got|
      exp.merge(got) do |_k, exp_counts, got_counts|
        exp_counts.zip(got_counts).map { |a, b| a + b }
      end
    end

    unless @show_common_queries
      combined_counts = combined_counts.transform_values do |suffs|
        suffs.reject { |_k, counts| counts.first == counts.second }
      end
    end

    combined_counts.reject { |_prefix, suffs| suffs.empty? }
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
      sections = diff_counts.map { |q, suffixes| diff_query_group_message(q, suffixes) }

      <<~MSG
      Query Diff:
      -----------
      #{sections.join("\n\n")}
      MSG
    else
      @recorder.log_message
    end
  end

  def skip_cached
    true
  end

  def verify_count(&block)
    @subject_block = block
    actual_count > maximum
  end

  def maximum
    expected_count + threshold
  end

  def failure_message
    threshold_message = threshold > 0 ? " (+#{threshold})" : ''
    counts = "#{expected_count}#{threshold_message}"
    "Expected a maximum of #{counts} queries, got #{actual_count}:\n\n#{log_message}"
  end

  def strip_marginalia_annotations(logs)
    logs.map { |log| log.sub(MARGINALIA_ANNOTATION_REGEX, '') }
  end
end

RSpec::Matchers.define :issue_fewer_queries_than do
  supports_block_expectations

  include ExceedQueryLimitHelpers

  def control
    block_arg
  end

  def control_recorder
    @control_recorder ||= ActiveRecord::QueryRecorder.new(&control)
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

    actual_count < expected_count
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

RSpec::Matchers.define :issue_same_number_of_queries_as do
  supports_block_expectations

  include ExceedQueryLimitHelpers

  def control
    block_arg
  end

  chain :or_fewer do
    @or_fewer = true
  end

  chain :ignoring_cached_queries do
    @skip_cached = true
  end

  def control_recorder
    @control_recorder ||= ActiveRecord::QueryRecorder.new(&control)
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

    if @or_fewer
      actual_count <= expected_count
    else
      (expected_count - actual_count).abs <= threshold
    end
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

    ["#{expected_count}", or_fewer_msg, threshold_msg].compact.join(' ')
  end

  def skip_cached
    @skip_cached || false
  end
end

RSpec::Matchers.define :exceed_all_query_limit do |expected|
  supports_block_expectations

  include ExceedQueryLimitHelpers

  match do |block|
    verify_count(&block)
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
    verify_count(&block)
  end

  failure_message_when_negated do |actual|
    failure_message
  end
end
