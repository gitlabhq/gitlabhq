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
