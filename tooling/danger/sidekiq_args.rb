# frozen_string_literal: true

module Tooling
  module Danger
    module SidekiqArgs
      include ::Danger::Helpers

      WORKER_FILES_REGEX = 'app/workers'
      EE_PREFIX = 'ee/'
      DEF_PERFORM = "def perform"
      DEF_PERFORM_REGEX = /[\s+-]*def perform\((.*)\)/
      BEFORE_DEF_PERFORM_REGEX = /^[\s-]*def perform\b/
      AFTER_DEF_PERFORM_REGEX = /^[\s+]*def perform\b/

      MR_WARNING_COMMENT = <<~WARNING_COMMENT
        Please follow the [Sidekiq development guidelines](https://docs.gitlab.com/ee/development/sidekiq/compatibility_across_updates.html#changing-the-arguments-for-a-worker) when changing Sidekiq worker arguments.
      WARNING_COMMENT

      SUGGEST_MR_COMMENT = <<~SUGGEST_COMMENT
        Please follow the [Sidekiq development guidelines](https://docs.gitlab.com/ee/development/sidekiq/compatibility_across_updates.html#changing-the-arguments-for-a-worker) when changing Sidekiq worker arguments.

        In particular, check whether you are updating callers of this method in this MR, and ensure that your change will be backwards compatible across updates.
      SUGGEST_COMMENT

      def changed_worker_files(ee: :include)
        changed_files = helper.all_changed_files
        folder_prefix =
          case ee
          when :include
            "(#{EE_PREFIX})?"
          when :only
            EE_PREFIX
          when :exclude
            nil
          end

        changed_files.grep(%r{\A#{folder_prefix}#{WORKER_FILES_REGEX}})
      end

      def args_changed?(diff)
        # Find the "before" and "after" versions of the perform method definition
        before_def_perform = diff.find { |line| BEFORE_DEF_PERFORM_REGEX.match?(line) }
        after_def_perform = diff.find { |line| AFTER_DEF_PERFORM_REGEX.match?(line) }

        # args are not changed if there is no before or after def perform method
        return false unless before_def_perform && after_def_perform

        # Extract the perform  method arguments from the "before" and "after" versions
        before_args, after_args = diff.flat_map { |line| line.scan(DEF_PERFORM_REGEX) }

        before_args != after_args
      end

      def add_comment_for_matched_line(filename)
        diff = helper.changed_lines(filename)
        return unless args_changed?(diff)

        file_lines = project_helper.file_lines(filename)

        perform_method_line = file_lines.index { |line| line.include?(DEF_PERFORM) }
        markdown(format(SUGGEST_MR_COMMENT), file: filename, line: perform_method_line.succ)
        warn(MR_WARNING_COMMENT)
      end
    end
  end
end
