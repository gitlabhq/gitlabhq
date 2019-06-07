module ActiveRecord
  class QueryRecorder
    attr_reader :log, :skip_cached, :cached

    def initialize(skip_cached: true, &block)
      @log = []
      @cached = []
      @skip_cached = skip_cached
      ActiveSupport::Notifications.subscribed(method(:callback), 'sql.active_record', &block)
    end

    def show_backtrace(values)
      Rails.logger.debug("QueryRecorder SQL: #{values[:sql]}")
      caller.each { |line| Rails.logger.debug("   --> #{line}") }
    end

    def callback(name, start, finish, message_id, values)
      show_backtrace(values) if ENV['QUERY_RECORDER_DEBUG']

      if values[:cached] && skip_cached
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
