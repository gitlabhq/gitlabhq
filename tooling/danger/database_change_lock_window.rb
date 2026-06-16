# frozen_string_literal: true

module Tooling
  module Danger
    module DatabaseChangeLockWindow
      LOCK_CONFIG_PATH = 'config/database_change_lock.yml'
      SECONDS_PER_DAY = 86400
      DEFAULT_MERGE_BUFFER_DAYS = 2

      private

      def config_file_exists?
        File.exist?(LOCK_CONFIG_PATH)
      end

      def config
        @config ||= load_active_lock_config
      end

      def load_active_lock_config
        lock_configs = YAML.safe_load_file(LOCK_CONFIG_PATH)['locks']
        find_active_lock(lock_configs) || {}
      rescue Errno::ENOENT
        {}
      end

      def find_active_lock(lock_configs)
        now = time_current

        lock_configs.find do |lock_config|
          next unless valid_lock_config?(lock_config)

          time_range = calculate_time_range(lock_config)
          now.between?(time_range[:start], time_range[:end])
        end
      end

      def valid_lock_config?(lock_config)
        lock_config['start_date'] && lock_config['end_date']
      end

      def calculate_time_range(lock_config)
        warning_offset = lock_config['warning_days'].to_i * SECONDS_PER_DAY
        merge_buffer = (lock_config['merge_buffer'] || DEFAULT_MERGE_BUFFER_DAYS).to_i * SECONDS_PER_DAY
        maintenance_start = parse_date(lock_config['start_date'].to_s)

        {
          start: maintenance_start - merge_buffer - warning_offset,
          end: parse_date(lock_config['end_date'].to_s)
        }
      end

      def maintenance_start_date
        @maintenance_start_date ||= parse_date(config['start_date'].to_s)
      end

      def merge_lock_start_date
        @merge_lock_start_date ||= maintenance_start_date - (merge_buffer_days * SECONDS_PER_DAY)
      end

      def end_date
        @end_date ||= parse_date(config['end_date'].to_s)
      end

      def details
        @details ||= config['details'].to_s
      end

      def change_request_issue_url
        @change_request_issue_url ||= config['change_request_issue_url'].to_s
      end

      def warning_days
        @warning_days ||= config['warning_days'].to_i
      end

      def merge_buffer_days
        @merge_buffer_days ||= (config['merge_buffer'] || DEFAULT_MERGE_BUFFER_DAYS).to_i
      end

      def lock_active?
        time_current.between?(merge_lock_start_date, end_date)
      end

      def within_warning_period?
        warning_start = merge_lock_start_date - (warning_days * SECONDS_PER_DAY)
        time_current.between?(warning_start, merge_lock_start_date - 1)
      end

      def config_valid?
        valid_dates? && warning_days > 0
      end

      def valid_dates?
        maintenance_start_date && end_date && merge_lock_start_date < end_date && end_date >= time_current
      end

      def days_until_lock
        return unless merge_lock_start_date

        ((merge_lock_start_date - time_current) / SECONDS_PER_DAY).to_i
      end

      def message_params
        {
          maintenance_start_date: maintenance_start_date,
          merge_lock_start_date: merge_lock_start_date,
          end_date: end_date,
          details: details,
          change_request_issue_url: change_request_issue_url,
          merge_buffer_days: merge_buffer_days
        }
      end

      def parse_date(date)
        Time.iso8601(date)
      rescue ArgumentError
        nil
      end

      def time_current
        Time.now.utc
      end
    end
  end
end
