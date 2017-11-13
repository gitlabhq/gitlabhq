module ActiveRecord
  class QueryRecorder
    attr_reader :log, :cached

    def initialize(&block)
      @log = []
      @cached = []
      ActiveSupport::Notifications.subscribed(method(:callback), 'sql.active_record', &block)
    end

    def callback(name, start, finish, message_id, values)
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

  def log_message
    if expected.is_a?(ActiveRecord::QueryRecorder)
      extra_queries = (expected.log - @recorder.log).join("\n\n")
      "Extra queries: \n\n #{extra_queries}"
    else
      @recorder.log_message
    end
  end
end
