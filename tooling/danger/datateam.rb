# frozen_string_literal: true

module Tooling
  module Danger
    module Datateam
      CHANGED_SCHEMA_MESSAGE = <<~MSG
        Notification to the Data Team about changes to files with possible impact on Data Warehouse, add label `Data Warehouse::Impact Check`.

        /label ~"Data Warehouse::Impact Check"

        The following files require a review:

      MSG

      DATA_WAREHOUSE_SCOPE = 'Data Warehouse::'
      FILE_PATH_REGEX = %r{((ee|jh)/)?config/metrics(/.+\.yml)}
      PERFORMANCE_INDICATOR_REGEX = %r{gmau|smau|paid_gmau|umau}
      METRIC_REMOVED = %r{\+status: removed}
      DATABASE_REGEX = %r{\Adb/structure\.sql}
      DATABASE_METRIC_ADDED = %r{\+data_source: database}
      DATABASE_LINE_REMOVAL_REGEX = %r{\A-}

      def build_message
        return unless impacted?

        CHANGED_SCHEMA_MESSAGE + helper.markdown_list(data_warehouse_impact_files)
      end

      def impacted?
        !labelled_as_datawarehouse? && data_warehouse_impact_files.any?
      end

      private

      def data_warehouse_impact_files
        @impacted_files ||= (metrics_added_files + metrics_changed_files + database_changed_files)
      end

      def labelled_as_datawarehouse?
        helper.mr_labels.any? { |label| label.start_with?(DATA_WAREHOUSE_SCOPE) }
      end

      def metrics_added_files
        metrics_definitions_files = helper.added_files.grep(FILE_PATH_REGEX)

        metrics_definitions_files.select do |file|
          helper.changed_lines(file).any? { |change| database_metric_added?(change) }
        end.compact
      end

      def metrics_changed_files
        metrics_definitions_files = helper.modified_files.grep(FILE_PATH_REGEX)

        metrics_definitions_files.select do |file|
          helper.changed_lines(file).any? { |change| performance_indicator_changed?(change) || status_removed?(change) }
        end.compact
      end

      def database_changed_files
        database_changed_files = helper.modified_files.grep(DATABASE_REGEX)
        database_changed_files.select do |file|
          helper.changed_lines(file).any? { |change| database_line_removal?(change) }
        end.compact
      end

      def database_line_removal?(change)
        change =~ DATABASE_LINE_REMOVAL_REGEX
      end

      def performance_indicator_changed?(change)
        change =~ PERFORMANCE_INDICATOR_REGEX
      end

      def status_removed?(change)
        change =~ METRIC_REMOVED
      end

      def database_metric_added?(change)
        change =~ DATABASE_METRIC_ADDED
      end
    end
  end
end
