module ActiveRecord
  class QueryRecorder
    attr_reader :log, :cached

    def initialize(&block)
      @log = []
      @cached = []
      ActiveSupport::Notifications.subscribed(method(:callback), 'sql.active_record', &block)
    end

    def show_backtrace(values)
      Rails.logger.debug("QueryRecorder SQL: #{values[:sql]}")
      caller.each { |line| Rails.logger.debug("   --> #{line}") }
    end

    def callback(name, start, finish, message_id, values)
      show_backtrace(values) if ENV['QUERY_RECORDER_DEBUG']

      if values[:name]&.include?("CACHE")
        @cached << values[:sql]
      elsif !values[:name]&.include?("SCHEMA")
        @log << values[:sql]
      end
    end

    def count
      @log.count
    end

    def cached_count
      @cached.count
    end

    def log_message
      @log.join("\n\n")
    end
  end
end

RSpec::Matchers.define :exceed_query_limit do |expected|
  supports_block_expectations

  match do |block|
    query_count(&block) > expected_count + threshold
  end

  failure_message_when_negated do |actual|
    threshold_message = threshold > 0 ? " (+#{@threshold})" : ''
    counts = "#{expected_count}#{threshold_message}"
    "Expected a maximum of #{counts} queries, got #{actual_count}:\n\n#{log_message}"
  end

  def with_threshold(threshold)
    @threshold = threshold
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
    @recorder.count
  end

  def query_count(&block)
    @recorder = ActiveRecord::QueryRecorder.new(&block)
    @recorder.count
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
end
