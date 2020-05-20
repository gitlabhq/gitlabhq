# frozen_string_literal: true

module ActiveRecord
  class QueryRecorder
    attr_reader :log, :skip_cached, :cached, :data
    UNKNOWN = %w(unknown unknown).freeze

    def initialize(skip_cached: true, query_recorder_debug: false, &block)
      @data = Hash.new { |h, k| h[k] = { count: 0, occurrences: [], backtrace: [] } }
      @log = []
      @cached = []
      @skip_cached = skip_cached
      @query_recorder_debug = query_recorder_debug
      # force replacement of bind parameters to give tests the ability to check for ids
      ActiveRecord::Base.connection.unprepared_statement do
        ActiveSupport::Notifications.subscribed(method(:callback), 'sql.active_record', &block)
      end
    end

    def show_backtrace(values)
      Rails.logger.debug("QueryRecorder SQL: #{values[:sql]}")
      Gitlab::BacktraceCleaner.clean_backtrace(caller).each do |line|
        Rails.logger.debug("QueryRecorder backtrace:  --> #{line}")
      end
    end

    def get_sql_source(sql)
      matches = sql.match(/,line:(?<line>.*):in\s+`(?<method>.*)'\*\//)
      matches ? [matches[:line], matches[:method]] : UNKNOWN
    end

    def store_sql_by_source(values: {}, backtrace: nil)
      full_name = get_sql_source(values[:sql]).join(':')
      @data[full_name][:count] += 1
      @data[full_name][:occurrences] << values[:sql]
      @data[full_name][:backtrace] << backtrace
    end

    def find_query(query_regexp, limit, first_only: false)
      out = []

      @data.each_pair do |k, v|
        if v[:count] > limit && k.match(query_regexp)
          out << [k, v[:count]]
          break if first_only
        end
      end

      out.flatten! if first_only
      out
    end

    def occurrences_by_line_method
      @occurrences_by_line_method ||= @data.sort_by { |_, v| v[:count] }
    end

    def callback(name, start, finish, message_id, values)
      store_backtrace = ENV['QUERY_RECORDER_DEBUG'] || @query_recorder_debug
      backtrace = store_backtrace ? show_backtrace(values) : nil

      if values[:cached] && skip_cached
        @cached << values[:sql]
      elsif !values[:name]&.include?("SCHEMA")
        @log << values[:sql]
        store_sql_by_source(values: values, backtrace: backtrace)
      end
    end

    def count
      @count ||= @log.count
    end

    def cached_count
      @cached_count ||= @cached.count
    end

    def log_message
      @log_message ||= @log.join("\n\n")
    end

    def occurrences
      @occurrences ||= @log.group_by(&:to_s).transform_values(&:count)
    end
  end
end
