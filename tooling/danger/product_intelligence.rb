# frozen_string_literal: true
# rubocop:disable Style/SignalException

module Tooling
  module Danger
    module ProductIntelligence
      WORKFLOW_LABELS = [
        'product intelligence::approved',
        'product intelligence::review pending'
      ].freeze

      TRACKING_FILES = [
        'lib/gitlab/tracking.rb',
        'spec/lib/gitlab/tracking_spec.rb',
        'app/helpers/tracking_helper.rb',
        'spec/helpers/tracking_helper_spec.rb',
        'app/assets/javascripts/tracking/index.js',
        'app/assets/javascripts/tracking/constants.js',
        'app/assets/javascripts/tracking/get_standard_context.js',
        'spec/frontend/tracking/get_standard_context_spec.js',
        'spec/frontend/tracking_spec.js',
        'generator_templates/usage_metric_definition/metric_definition.yml',
        'lib/generators/gitlab/usage_metric/usage_metric_generator.rb',
        'lib/generators/gitlab/usage_metric_definition_generator.rb',
        'lib/generators/gitlab/usage_metric_definition/redis_hll_generator.rb',
        'spec/lib/generators/gitlab/usage_metric_generator_spec.rb',
        'spec/lib/generators/gitlab/usage_metric_definition_generator_spec.rb',
        'spec/lib/generators/gitlab/usage_metric_definition/redis_hll_generator_spec.rb',
        'config/metrics/schema.json'
      ].freeze

      def missing_labels
        return [] unless helper.ci?

        labels = []
        labels << 'product intelligence' unless helper.mr_has_labels?('product intelligence')
        labels << 'product intelligence::review pending' unless helper.mr_has_labels?(WORKFLOW_LABELS)

        labels
      end

      def matching_changed_files
        tracking_changed_files = all_changed_files & TRACKING_FILES
        usage_data_changed_files = all_changed_files.grep(%r{(usage_data)})

        usage_data_changed_files + tracking_changed_files + metrics_changed_files + dictionary_changed_file + snowplow_changed_files
      end

      def need_dictionary_changes?
        required_dictionary_update_changed_files.any? && dictionary_changed_file.empty?
      end

      private

      def all_changed_files
        helper.all_changed_files
      end

      def dictionary_changed_file
        all_changed_files.grep(%r{(doc/development/usage_ping/dictionary\.md)})
      end

      def metrics_changed_files
        all_changed_files.grep(%r{((ee/)?config/metrics/.*\.yml)})
      end

      def matching_files?(file, extension:, pattern:)
        return unless file.end_with?(extension)

        helper.changed_lines(file).grep(pattern).any?
      end

      def snowplow_changed_files
        js_patterns = Regexp.union(
          'Tracking.event',
          /\btrack\(/,
          'data-track-event',
          'data-track-action'
        )
        all_changed_files.select do |file|
          matching_files?(file, extension: '.rb', pattern: %r{Gitlab::Tracking\.(event|enabled\?|snowplow_options)$}) ||
            matching_files?(file, extension: '.js', pattern: js_patterns) ||
            matching_files?(file, extension: '.vue', pattern: js_patterns) ||
            matching_files?(file, extension: '.haml', pattern: %r{data: \{ track})
        end
      end

      def required_dictionary_update_changed_files
        dictionary_pattern = Regexp.union(
          'key_path:',
          'description:',
          'product_section:',
          'product_stage:',
          'product_group:',
          'status:',
          'tier:'
        )

        metrics_changed_files.select do |file|
          matching_files?(file, extension: '.yml', pattern: dictionary_pattern)
        end
      end
    end
  end
end
