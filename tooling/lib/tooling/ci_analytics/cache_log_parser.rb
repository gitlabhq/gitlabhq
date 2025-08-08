# frozen_string_literal: true

module Tooling
  module CiAnalytics
    class CacheLogParser
      CACHE_PATTERNS = {
        checking: /Checking cache for (.+)\.\.\./,
        downloading: /Downloading cache from/,
        hit: /Successfully extracted cache|cache\.zip is up to date/,
        miss: /WARNING: file does not exist/,
        creating: /Creating cache (.+)\.\.\./,
        created: /Created cache/
      }.freeze

      PACKAGE_REGISTRY_PATTERNS = {
        package_not_found: /The archive was not found\. The server returned status 404\./,
        package_downloaded: /The archive was found. The server returned status 200\./,
        package_uploaded: /\{"message":"201 Created"\}/
      }.freeze

      OPERATION_PATTERNS = {
        bundle_start: /Installing gems/,
        bundle_success: /Bundle complete!/,
        yarn_start: /Installing Yarn packages|yarn install v/,
        yarn_success: /Done in (.+)s\./,
        assets_start: /Compiling frontend assets/,
        assets_success: /gitlab:assets:fix_urls.*finished/
      }.freeze

      def self.extract_cache_events(log_content)
        events = []
        current_cache = {}
        current_package_cache = {}
        operation_timings = {}

        log_content.each_line do |line|
          timestamp = extract_timestamp(line) || Time.now

          parse_cache_operations(line, timestamp, current_cache, events)
          parse_package_registry_operations(line, timestamp, current_package_cache, events)
          parse_operations(line, timestamp, operation_timings)
        end

        correlate_operations(events, operation_timings)
        events.compact
      end

      def self.parse_cache_operations(line, timestamp, current_cache, events)
        case line
        when CACHE_PATTERNS[:checking]
          cache_key = ::Regexp.last_match(1).strip
          current_cache.clear
          current_cache.merge!({
            cache_key: cache_key,
            cache_type: infer_cache_type(cache_key),
            cache_operation: 'pull',
            started_at: timestamp
          })

        when CACHE_PATTERNS[:downloading]
          current_cache[:cache_result] = 'hit'
          current_cache[:cache_size_bytes] = extract_cache_size(line)

        when CACHE_PATTERNS[:hit]
          if current_cache[:cache_key]
            current_cache[:cache_result] = 'hit'
            current_cache[:duration] = calculate_duration(current_cache[:started_at], timestamp)
            events << current_cache.dup
            current_cache.clear
          end

        when CACHE_PATTERNS[:miss]
          if current_cache[:cache_key]
            current_cache[:cache_result] = 'miss'
            current_cache[:duration] = calculate_duration(current_cache[:started_at], timestamp)
            current_cache[:cache_size_bytes] = nil
            events << current_cache.dup
            current_cache.clear
          end

        when CACHE_PATTERNS[:creating]
          cache_key = ::Regexp.last_match(1).strip
          events << {
            cache_key: cache_key,
            cache_type: infer_cache_type(cache_key),
            cache_operation: 'push',
            cache_result: 'creating',
            started_at: timestamp
          }

        when CACHE_PATTERNS[:created]
          last_push = events.reverse.find { |e| e[:cache_operation] == 'push' }
          if last_push
            last_push[:cache_result] = 'created'
            last_push[:duration] = calculate_duration(last_push[:started_at], timestamp)
            last_push[:cache_size_bytes] = extract_cache_size(line)
          end
        end
      end

      def self.parse_package_registry_operations(line, timestamp, current_package_cache, events)
        case line
        when PACKAGE_REGISTRY_PATTERNS[:package_downloaded]
          handle_package_downloaded(timestamp, current_package_cache, events)
        when PACKAGE_REGISTRY_PATTERNS[:package_not_found]
          handle_package_not_found(timestamp, current_package_cache, events)
        when PACKAGE_REGISTRY_PATTERNS[:package_uploaded]
          handle_package_uploaded(timestamp, events)
        end
      end

      def self.handle_package_downloaded(timestamp, current_package_cache, events)
        return unless current_package_cache[:cache_key]

        # Successfully fetched assets = cache hit
        current_package_cache[:cache_result] = 'hit'
        current_package_cache[:duration] = calculate_duration(current_package_cache[:started_at], timestamp)
        events << current_package_cache.dup
        current_package_cache.clear
      end

      def self.handle_package_not_found(timestamp, current_package_cache, events)
        return unless current_package_cache[:cache_key]

        current_package_cache[:cache_result] = 'miss'
        current_package_cache[:duration] = calculate_duration(current_package_cache[:started_at], timestamp)
        current_package_cache[:cache_size_bytes] = nil
        events << current_package_cache.dup
        current_package_cache.clear
      end

      def self.handle_package_uploaded(timestamp, events)
        last_upload = events.reverse.find { |e| e[:cache_operation] == 'push' }
        return unless last_upload

        last_upload[:cache_result] = 'created'
        last_upload[:duration] = calculate_duration(last_upload[:started_at], timestamp)
        last_upload[:cache_size_bytes] = nil
      end

      def self.parse_operations(line, timestamp, operation_timings)
        case line
        when OPERATION_PATTERNS[:bundle_start]
          operation_timings[:bundle] = { started_at: timestamp }
        when OPERATION_PATTERNS[:bundle_success]
          if operation_timings[:bundle]
            operation_timings[:bundle][:duration] =
              calculate_duration(operation_timings[:bundle][:started_at], timestamp)
            operation_timings[:bundle][:success] = true
          end
        when OPERATION_PATTERNS[:yarn_start]
          operation_timings[:yarn] = { started_at: timestamp }
        when OPERATION_PATTERNS[:yarn_success]
          if operation_timings[:yarn]
            duration_match = line.match(/Done in (.+)s\./)
            operation_timings[:yarn][:duration] = duration_match[1].to_f if duration_match
            operation_timings[:yarn][:success] = true
          end
        when OPERATION_PATTERNS[:assets_start]
          operation_timings[:assets] = { started_at: timestamp }
        when OPERATION_PATTERNS[:assets_success]
          if operation_timings[:assets]
            operation_timings[:assets][:duration] =
              calculate_duration(operation_timings[:assets][:started_at], timestamp)
            operation_timings[:assets][:success] = true
          end
        end
      end

      def self.correlate_operations(events, operation_timings)
        events.each do |event|
          operation_key = case event[:cache_type]
                          when 'ruby-gems', 'qa-ruby-gems' then :bundle
                          when 'node-modules' then :yarn
                          when 'assets' then :assets
                          end

          next unless operation_key && operation_timings[operation_key]

          operation = operation_timings[operation_key]
          event[:operation_command] = infer_operation_command(event[:cache_key], event[:cache_type])
          event[:operation_duration] = operation[:duration]
          event[:operation_success] = operation[:success]
        end
      end

      def self.infer_cache_type(cache_key)
        case cache_key.downcase
        when /ruby-gems/ then 'ruby-gems'
        when /node-modules/ then 'node-modules'
        when /go-pkg/, /gitaly/ then 'go'
        when /assets/ then 'assets'
        when /rubocop/ then 'rubocop'
        when /qa-ruby/ then 'qa-ruby-gems'
        when /helm/ then 'cng-helm'
        else 'unknown'
        end
      end

      def self.infer_operation_command(cache_key, cache_type = nil)
        type = cache_type || infer_cache_type(cache_key)

        case type
        when 'ruby-gems', 'qa-ruby-gems' then 'bundle install'
        when 'node-modules' then 'yarn install'
        when 'assets' then 'assets compilation'
        when 'rubocop' then 'rubocop analysis'
        end
      end

      def self.extract_timestamp(line)
        match = line.match(/(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2})/)
        Time.parse(match[1]) if match
      rescue StandardError
        nil
      end

      def self.calculate_duration(start_time, end_time)
        return unless start_time && end_time

        (end_time - start_time).round(2)
      end

      def self.extract_cache_size(line)
        extract_size_from_line(line, /(\d+(?:\.\d+)?)\s*([KM])B/i)
      end

      def self.extract_package_size(line)
        extract_size_from_line(line, /(\d+(?:\.\d+)?)\s*([KM]B)/i)
      end

      def self.extract_size_from_line(line, unit_pattern)
        case line
        when /(\d+)\s*bytes/i
          ::Regexp.last_match(1).to_i
        when unit_pattern
          size = ::Regexp.last_match(1).to_f
          unit = ::Regexp.last_match(2).upcase.delete('B')

          case unit
          when 'K' then (size * 1024).to_i
          when 'M' then (size * 1024 * 1024).to_i
          else size.to_i
          end
        end
      end
    end
  end
end
