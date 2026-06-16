# frozen_string_literal: true

require_relative 'database_change_lock_window'

module Tooling
  module Danger
    # Base class for the lock rules dispatched by Tooling::Danger::DatabaseChangeLock.
    #
    # The shared flow (warn while a lock is upcoming, fail while it is active) lives here.
    # Subclasses only describe which changes they guard (#relevant_change?) and the copy
    # shown to the author (#warning_message_template, #lock_message_template).
    #
    # Instances are not Danger plugins themselves; they receive the dispatching plugin as
    # +context+ and delegate the Danger DSL (warn/fail/helper) to it.
    class DatabaseChangeLockRule
      include DatabaseChangeLockWindow

      def initialize(context)
        @context = context
      end

      def check_lock
        return unless config_file_exists? && config_valid?

        context.warn(warning_message) if should_warn?
        context.fail(lock_message) if should_fail?
      end

      private

      attr_reader :context

      def helper
        context.helper
      end

      def should_warn?
        within_warning_period? && relevant_change?
      end

      def should_fail?
        relevant_change? && lock_active? && helper.ci?
      end

      def lock_message
        format(lock_message_template, message_params.merge(schedule: schedule('Merge lock started at')))
      end

      def warning_message
        format(
          warning_message_template,
          message_params.merge(days_until_lock: days_until_lock, schedule: schedule('Merge lock starts at'))
        )
      end

      # Renders the window start and, unless the merge lock starts at the same moment
      # (i.e. merge_buffer is 0), the earlier merge lock date. Collapsing to a single
      # line avoids showing two identical dates.
      def schedule(merge_lock_label)
        lines = ["#{lock_window_label}: #{maintenance_start_date}"]
        lines << "#{merge_lock_label}: #{merge_lock_start_date}" unless merge_lock_start_date == maintenance_start_date
        lines.join("\n")
      end

      def relevant_change?
        raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
      end

      def lock_window_label
        raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
      end

      def lock_message_template
        raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
      end

      def warning_message_template
        raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
      end
    end
  end
end
