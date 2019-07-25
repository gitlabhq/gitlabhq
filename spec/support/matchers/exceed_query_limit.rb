# frozen_string_literal: true

module ExceedQueryLimitHelpers
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
      counts = count_queries(expected.log)
      extra_queries = @recorder.log.reject { |query| counts[query] -= 1 unless counts[query].zero? }
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
    actual_count > expected_count + threshold
  end

  def failure_message
    threshold_message = threshold > 0 ? " (+#{@threshold})" : ''
    counts = "#{expected_count}#{threshold_message}"
    "Expected a maximum of #{counts} queries, got #{actual_count}:\n\n#{log_message}"
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
