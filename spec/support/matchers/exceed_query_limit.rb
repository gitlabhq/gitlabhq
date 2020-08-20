# frozen_string_literal: true

module ExceedQueryLimitHelpers
  MARGINALIA_ANNOTATION_REGEX = %r{\s*\/\*.*\*\/}.freeze

  def with_threshold(threshold)
    @threshold = threshold
    self
  end

  def for_query(query)
    @query = query
    self
  end

  def threshold
    @threshold.to_i
  end

  def expected_count
    if expected.is_a?(ActiveRecord::QueryRecorder)
      expected.count
    else
      expected
    end
  end

  def actual_count
    @actual_count ||= if @query
                        recorder.log.select { |recorded| recorded =~ @query }.size
                      else
                        recorder.count
                      end
  end

  def recorder
    @recorder ||= ActiveRecord::QueryRecorder.new(skip_cached: skip_cached, &@subject_block)
  end

  def count_queries(queries)
    queries.each_with_object(Hash.new(0)) { |query, counts| counts[query] += 1 }
  end

  def log_message
    if expected.is_a?(ActiveRecord::QueryRecorder)
      counts = count_queries(strip_marginalia_annotations(expected.log))
      extra_queries = strip_marginalia_annotations(@recorder.log).reject { |query| counts[query] -= 1 unless counts[query] == 0 }
      extra_queries_display = count_queries(extra_queries).map { |query, count| "[#{count}] #{query}" }

      (['Extra queries:'] + extra_queries_display).join("\n\n")
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
