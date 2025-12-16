# frozen_string_literal: true

module Tooling
  module Danger
    module DatabaseUpgradeDdlLock
      BACKGROUND_ISSUE_URL = 'https://gitlab.com/gitlab-org/gitlab/-/issues/579388'
      LOCK_CONFIG_PATH = 'config/database_upgrade_ddl_lock.yml'
      SCHEMA_FILE_PATTERN = %r{\Adb/structure\.sql}
      SECONDS_PER_DAY = 86400

      def check_ddl_lock_contention
        return unless config_file_exists? && config_valid?

        warn warning_message if should_warn?
        fail lock_message if should_fail?
      end

      private

      def should_warn?
        within_warning_period? && schema_modified?
      end

      def should_fail?
        schema_modified? && ddl_lock_active? && helper.ci?
      end

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
        {
          start: parse_date(lock_config['start_date'].to_s) - warning_offset,
          end: parse_date(lock_config['end_date'].to_s)
        }
      end

      def start_date
        @start_date ||= parse_date(config['start_date'].to_s)
      end

      def end_date
        @end_date ||= parse_date(config['end_date'].to_s)
      end

      def details
        @details ||= config['details'].to_s
      end

      def upgrade_issue_url
        @upgrade_issue_url ||= config['upgrade_issue_url'].to_s
      end

      def warning_days
        @warning_days ||= config['warning_days'].to_i
      end

      def ddl_lock_active?
        time_current.between?(start_date, end_date)
      end

      def within_warning_period?
        warning_start = start_date - (warning_days * SECONDS_PER_DAY)
        time_current.between?(warning_start, start_date - 1)
      end

      def lock_message
        format(lock_message_template, message_params)
      end

      def lock_message_template
        <<~MSG
          Merging migrations that change schema is currently disabled while a major database upgrade is
          performed. After the lock expires, retry this job and danger will pass.

          See change request: %<upgrade_issue_url>s

          Started at: %<start_date>s
          Locked until: %<end_date>s
          Details: %<details>s
          Background: #{BACKGROUND_ISSUE_URL}
        MSG
      end

      def warning_message
        format(warning_message_template, message_params.merge(days_until_lock: days_until_lock))
      end

      def warning_message_template
        <<~MSG
          A database upgrade lock will be active in %<days_until_lock>s day(s). Starting at %<start_date>s, merging
          migrations that changes the schema (DDL) will be disabled while a major database upgrade is performed.
          Plan accordingly or consider merging your changes before the lock begins.

          See change request: %<upgrade_issue_url>s

          Starts at: %<start_date>s
          Locked until: %<end_date>s
          Details: %<details>s
          Background: #{BACKGROUND_ISSUE_URL}
        MSG
      end

      def message_params
        {
          start_date: start_date,
          end_date: end_date,
          details: details,
          upgrade_issue_url: upgrade_issue_url
        }
      end

      def schema_modified?
        helper.all_changed_files.grep(SCHEMA_FILE_PATTERN).any?
      end

      def config_valid?
        valid_dates? && warning_days > 0
      end

      def valid_dates?
        start_date && end_date && start_date < end_date && end_date >= time_current
      end

      def days_until_lock
        return unless start_date

        ((start_date - time_current) / SECONDS_PER_DAY).to_i
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
