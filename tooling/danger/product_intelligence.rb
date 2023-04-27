# frozen_string_literal: true
# rubocop:disable Style/SignalException

module Tooling
  module Danger
    module ProductIntelligence
      METRIC_DIRS = %w[lib/gitlab/usage/metrics/instrumentations ee/lib/gitlab/usage/metrics/instrumentations].freeze
      APPROVED_LABEL = 'product intelligence::approved'
      REVIEW_LABEL = 'product intelligence::review pending'
      CHANGED_FILES_MESSAGE = <<~MSG
        For the following files, a review from the [Data team and Product Intelligence team](https://gitlab.com/groups/gitlab-org/analytics-section/product-intelligence/engineers/-/group_members?with_inherited_permissions=exclude) is recommended
        Please check the ~"product intelligence" [Service Ping guide](https://docs.gitlab.com/ee/development/service_ping/) or the [Snowplow guide](https://docs.gitlab.com/ee/development/snowplow/).

        For MR review guidelines, see the [Service Ping review guidelines](https://docs.gitlab.com/ee/development/service_ping/review_guidelines.html) or the [Snowplow review guidelines](https://docs.gitlab.com/ee/development/snowplow/review_guidelines.html).

        %<changed_files>s

      MSG

      CHANGED_SCOPE_MESSAGE = <<~MSG
        The following metrics could be affected by the modified scopes and require ~"product intelligence" review:

      MSG

      CHANGED_USAGE_DATA_MESSAGE = <<~MSG
        Notice that implementing metrics directly in usage_data.rb has been deprecated. ([Deprecated Usage Metrics](https://docs.gitlab.com/ee/development/service_ping/usage_data.html#usage-data-metrics-guide))
        Please use [Instrumentation Classes](https://docs.gitlab.com/ee/development/service_ping/metrics_instrumentation.html) instead.
      MSG

      WORKFLOW_LABELS = [
        APPROVED_LABEL,
        REVIEW_LABEL
      ].freeze

      def check!
        product_intelligence_paths_to_review = helper.changes.by_category(:product_intelligence).files

        labels_to_add = missing_labels

        return if product_intelligence_paths_to_review.empty? || skip_review?

        warn format(CHANGED_FILES_MESSAGE, changed_files: helper.markdown_list(product_intelligence_paths_to_review)) unless has_approved_label?

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

      private

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
            next unless mod_line =~ /^\+\s+scope :\w+/

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

      def each_metric(&block)
        METRIC_DIRS.each do |dir|
          Dir.glob(File.join(dir, '*.rb')).each(&block)
        end
      end

      def missing_labels
        return [] unless helper.ci?

        labels = []
        labels << 'product intelligence' unless helper.mr_has_labels?('product intelligence')
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
