# frozen_string_literal: true

module ActiveRecord
  class QueryRecorder
    attr_reader :log, :skip_cached, :skip_schema_queries, :cached, :data

    UNKNOWN = %w[unknown unknown].freeze

    def initialize(skip_cached: true, skip_schema_queries: true, log_file: nil, query_recorder_debug: false, &block)
      @data = Hash.new { |h, k| h[k] = { count: 0, occurrences: [], backtrace: [], durations: [] } }
      @log = []
      @cached = []
      @skip_cached = skip_cached
      @skip_schema_queries = skip_schema_queries
      @query_recorder_debug = ENV['QUERY_RECORDER_DEBUG'] || query_recorder_debug
      @log_file = log_file
      record(&block) if block
    end

    def record(&block)
      # force replacement of bind parameters to give tests the ability to check for ids
      ActiveSupport::Notifications.subscribed(method(:callback), 'sql.active_record', &block)
    end

    def show_backtrace(values, duration)
      values[:sql].lines.each do |line|
        print_to_log(:SQL, line)
      end
      print_to_log(:DURATION, duration)
      Gitlab::BacktraceCleaner.clean_backtrace(caller).each do |line|
        print_to_log(:backtrace, line)
      end
    end

    def print_to_log(label, line)
      msg = "QueryRecorder #{label}:  --> #{line}"

      if @log_file
        @log_file.puts(msg)
      else
        Rails.logger.debug(msg)
      end
    end

    def get_sql_source(sql)
      matches = sql.match(%r{,line:(?<line>.*):in\s+`(?<method>.*)'\*/})
      matches ? [matches[:line], matches[:method]] : UNKNOWN
    end

    def store_sql_by_source(values: {}, duration: nil, backtrace: nil)
      full_name = get_sql_source(values[:sql]).join(':')
      @data[full_name][:count] += 1
      @data[full_name][:occurrences] << values[:sql]
      @data[full_name][:backtrace] << backtrace
      @data[full_name][:durations] << duration
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
      duration = finish - start

      if values[:cached] && skip_cached
        @cached << values[:sql]
      elsif !ignorable?(values)

        backtrace = @query_recorder_debug ? show_backtrace(values, duration) : nil
        @log << values[:sql]
        store_sql_by_source(values: values, duration: duration, backtrace: backtrace)
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

    def occurrences_starting_with(str)
      occurrences.select { |query, _count| query.starts_with?(str) }
    end

    def ignorable?(values)
      return true if skip_schema_queries && values[:name]&.include?("SCHEMA")
      return true if values[:name]&.include?('License Load')

      false
    end
  end
end
