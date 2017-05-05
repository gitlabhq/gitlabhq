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
    query_count(&block) > expected
  end

  failure_message_when_negated do |actual|
    "Expected a maximum of #{expected} queries, got #{@recorder.count}:\n\n#{@recorder.log_message}"
  end

  def query_count(&block)
    @recorder = ActiveRecord::QueryRecorder.new(&block)
    @recorder.count
  end
end
