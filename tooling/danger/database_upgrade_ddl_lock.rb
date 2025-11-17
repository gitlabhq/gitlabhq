# frozen_string_literal: true

module Tooling
  module Danger
    module DatabaseUpgradeDdlLock
      LOCK_CONFIG_PATH = 'config/database_upgrade_ddl_lock.yml'
      SECONDS_PER_DAY = 86400

      def check_ddl_lock_contention
        return unless config_file_exists?

        return unless config_valid?

        # Always warn if within warning period.
        warn warning_message if within_warning_period? && schema_modified?

        fail lock_message if schema_modified? && ddl_lock_active? && helper.ci?
      end

      private

      def config_file_exists?
        File.exist?(LOCK_CONFIG_PATH)
      end

      def config
        @config ||= begin
          now = time_current
          lock_configs = YAML.safe_load_file(LOCK_CONFIG_PATH)['locks']

          lock_configs.find do |config|
            next unless config['start_date'] && config['end_date']

            start_date = parse_date(config['start_date'].to_s) - (config['warning_days'].to_i * SECONDS_PER_DAY)
            end_date = parse_date(config['end_date'].to_s)

            now.between?(start_date, end_date)
          end || {}
        rescue Errno::ENOENT
          {}
        end
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
        time_current >= warning_start && time_current < start_date
      end

      def lock_message
        msg = <<~MSG
          Merging migrations that change schema is currently disabled while a major database upgrade is
          performed. After the lock expires, retry this job and danger will pass.

          See change request: %<upgrade_issue_url>s

          Started at: %<start_date>s
          Locked until: %<end_date>s
          Details: %<details>s
          Background: https://gitlab.com/gitlab-org/gitlab/-/issues/579388
        MSG

        format(msg, start_date: start_date, end_date: end_date, details: details, upgrade_issue_url: upgrade_issue_url)
      end

      def warning_message
        msg = <<~MSG
          A database upgrade lock will be active in %<days_until_lock>s day(s). Starting at %<start_date>s, merging
          migrations that changes the schema (DDL) will be disabled while a major database upgrade is performed.
          Plan accordingly or consider merging your changes before the lock begins.

          See change request: %<upgrade_issue_url>s

          Starts at: %<start_date>s
          Locked until: %<end_date>s
          Details: %<details>s
          Background: https://gitlab.com/gitlab-org/gitlab/-/issues/579388
        MSG

        format(
          msg,
          days_until_lock: days_until_lock,
          start_date: start_date,
          end_date: end_date,
          details: details,
          upgrade_issue_url: upgrade_issue_url
        )
      end

      def schema_modified?
        helper.all_changed_files.grep(%r{\Adb/structure\.sql}).any?
      end

      def config_valid?
        valid_dates? && warning_days > 0
      end

      def valid_dates?
        !start_date.nil? && !end_date.nil? && start_date < end_date && end_date >= time_current
      end

      def days_until_lock
        return unless start_date

        ((start_date - time_current) / (24 * 60 * 60)).to_i
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
