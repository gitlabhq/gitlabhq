# frozen_string_literal: true

require_relative 'suggestor'

module Tooling
  module Danger
    module AnalyticsInstrumentation
      include ::Tooling::Danger::Suggestor

      METRIC_DIRS = %w[lib/gitlab/usage/metrics/instrumentations ee/lib/gitlab/usage/metrics/instrumentations].freeze
      APPROVED_LABEL = 'analytics instrumentation::approved'
      REVIEW_LABEL = 'analytics instrumentation::review pending'
      CHANGED_FILES_MESSAGE = <<~MSG
        For the following files, a review from the [Data team and Analytics Instrumentation team](https://gitlab.com/groups/gitlab-org/analytics-section/analytics-instrumentation/engineers/-/group_members?with_inherited_permissions=exclude) is recommended
        Please check the ~"analytics instrumentation" [Service Ping guide](https://docs.gitlab.com/ee/development/service_ping/) or the [Snowplow guide](https://docs.gitlab.com/ee/development/snowplow/).

        For MR review guidelines, see the [Internal Analytics review guidelines](https://docs.gitlab.com/ee/development/internal_analytics/review_guidelines.html).

        %<changed_files>s

      MSG

      CHANGED_SCOPE_MESSAGE = <<~MSG
        The following metrics could be affected by the modified scopes and require ~"analytics instrumentation" review:

      MSG

      CHANGED_USAGE_DATA_MESSAGE = <<~MSG
        Notice that implementing metrics directly in usage_data.rb has been deprecated.
        Please use [Instrumentation Classes](https://docs.gitlab.com/ee/development/internal_analytics/metrics/metrics_instrumentation.html) instead.
      MSG

      CHANGE_DEPRECATED_DATA_SOURCE_MESSAGE = <<~MSG
        Redis and RedisHLL tracking is deprecated, consider using Internal Events tracking instead https://docs.gitlab.com/ee/development/internal_analytics/internal_event_instrumentation/quick_start.html#defining-event-and-metrics
      MSG

      WORKFLOW_LABELS = [
        APPROVED_LABEL,
        REVIEW_LABEL
      ].freeze

      STATUS_REMOVED_REGEX = /^\+?status: removed\s?$/

      def check!
        analytics_instrumentation_paths_to_review = helper.changes.by_category(:analytics_instrumentation).files

        labels_to_add = missing_labels

        return if analytics_instrumentation_paths_to_review.empty? || skip_review?

        warn format(CHANGED_FILES_MESSAGE, changed_files: helper.markdown_list(analytics_instrumentation_paths_to_review)) unless has_approved_label?

        helper.labels_to_add.concat(labels_to_add) unless labels_to_add.empty?
      end

      def check_affected_scopes!
        metric_scope_list = metric_scope_affected
        return if metric_scope_list.empty?

        warn CHANGED_SCOPE_MESSAGE + convert_to_table(metric_scope_list)
        helper.labels_to_add.concat(missing_labels) unless missing_labels.empty?
      end

      def check_usage_data_insertions!
        usage_data_changes = helper.changed_lines("lib/gitlab/usage_data.rb")
        return if usage_data_changes.none? { |change| change.start_with?("+") }

        warn format(CHANGED_USAGE_DATA_MESSAGE)
      end

      def check_deprecated_data_sources!
        new_metric_files.each do |filename|
          add_suggestion(
            filename: filename,
            regex: /^\+?\s+data_source: redis\w*/,
            replacement: 'data_source: internal_events',
            comment_text: CHANGE_DEPRECATED_DATA_SOURCE_MESSAGE
          )
        end
      end

      def check_removed_metric_fields!
        modified_config_files.each do |filename|
          metric_removed = false
          has_removed_url = false
          has_removed_milestone = false
          helper.changed_lines(filename).each do |mod_line, _i|
            metric_removed = true if mod_line == '+status: removed'
            has_removed_url = true if /^\+removed_by_url:\s.+/.match?(mod_line)
            has_removed_milestone = true if /^\+milestone_removed:\s.+/.match?(mod_line)
          end

          next unless metric_removed
          next if has_removed_url && has_removed_milestone

          comment_removed_metric(filename, has_removed_url, has_removed_milestone)
        end
      end

      def warn_about_migrated_redis_keys_specs!
        override_files_changes = ["lib/gitlab/usage_data_counters/hll_redis_key_overrides.yml",
          "lib/gitlab/usage_data_counters/total_counter_redis_key_overrides.yml"].map do |filename|
          helper.changed_lines(filename).filter { |line| line.start_with?("+") }
        end
        return if override_files_changes.flatten.none?

        warn "Redis keys overrides were added. Please consider cover keys merging with specs. See the [related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/475191) for details"
      end

      private

      def modified_config_files
        helper.modified_files.select { |f| f.include?('config/metrics') && f.end_with?('yml') }
      end

      def comment_removed_metric(filename, has_removed_url, has_removed_milestone)
        mr_has_milestone = !helper.mr_milestone.nil?
        milestone = mr_has_milestone ? helper.mr_milestone['title'] : '[PLEASE SET MILESTONE]'
        comment_text = mr_has_milestone ? nil : "Please set the `milestone_removed` value manually"

        replacement = "status: removed\n"
        if !has_removed_url && !has_removed_milestone
          replacement += "removed_by_url: #{helper.mr_web_url}\nmilestone_removed: '#{milestone}'"
        elsif !has_removed_url
          replacement += "removed_by_url: #{helper.mr_web_url}"
          comment_text = nil
        elsif !has_removed_milestone
          replacement += "milestone_removed: '#{milestone}'"
        end

        add_suggestion(
          filename: filename,
          regex: STATUS_REMOVED_REGEX,
          replacement: replacement,
          comment_text: comment_text
        )
      end

      def convert_to_table(items)
        message = "Scope | Affected files |\n"
        message += "--- | ----- |\n"
        items.each_key do |scope|
          affected_files = items[scope]
          message += "`#{scope}`| `#{affected_files[0]}` |\n"
          affected_files[1..]&.each do |file_name|
            message += " | `#{file_name}` |\n"
          end
        end
        message
      end

      def metric_scope_affected
        select_models(helper.modified_files).each_with_object(Hash.new { |h, k| h[k] = [] }) do |file_name, matched_files|
          helper.changed_lines(file_name).each do |mod_line, _i|
            next unless /^\+\s+scope :\w+/.match?(mod_line)

            affected_scope = mod_line.match(/:\w+/)
            next if affected_scope.nil?

            affected_class = File.basename(file_name, '.rb').split('_').map(&:capitalize).join
            scope_name = "#{affected_class}.#{affected_scope[0][1..]}"

            each_metric do |metric_def|
              next unless File.read(metric_def).include?("relation { #{scope_name}")

              matched_files[scope_name].push(metric_def)
            end
          end
        end
      end

      def select_models(files)
        files.select do |f|
          f.start_with?('app/models/', 'ee/app/models/')
        end
      end

      def new_metric_files
        helper.added_files.select { |f| f.include?('config/metrics') && f.end_with?('.yml') }
      end

      def each_metric(&block)
        METRIC_DIRS.each do |dir|
          Dir.glob(File.join(dir, '*.rb')).each(&block)
        end
      end

      def missing_labels
        return [] unless helper.ci?

        labels = []
        labels << 'analytics instrumentation' unless helper.mr_has_labels?('analytics instrumentation')
        labels << REVIEW_LABEL unless has_workflow_labels?

        labels
      end

      def has_approved_label?
        helper.mr_labels.include?(APPROVED_LABEL)
      end

      def skip_review?
        helper.mr_has_labels?('growth experiment')
      end

      def has_workflow_labels?
        (WORKFLOW_LABELS & helper.mr_labels).any?
      end
    end
  end
end
