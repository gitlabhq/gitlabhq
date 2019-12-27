# frozen_string_literal: true

module ActiveRecord
  class QueryRecorder
    attr_reader :log, :skip_cached, :cached

    def initialize(skip_cached: true, &block)
      @log = []
      @cached = []
      @skip_cached = skip_cached
      # force replacement of bind parameters to give tests the ability to check for ids
      ActiveRecord::Base.connection.unprepared_statement do
        ActiveSupport::Notifications.subscribed(method(:callback), 'sql.active_record', &block)
      end
    end

    def show_backtrace(values)
      Rails.logger.debug("QueryRecorder SQL: #{values[:sql]}")
      Gitlab::BacktraceCleaner.clean_backtrace(caller).each { |line| Rails.logger.debug("   --> #{line}") }
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

    def occurrences
      @log.group_by(&:to_s).transform_values(&:count)
    end
  end
end
