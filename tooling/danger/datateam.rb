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
      FILE_PATH_REGEX = %r{((ee|jh)/)?config/metrics(/.+\.yml)}.freeze
      PERFORMANCE_INDICATOR_REGEX = %r{gmau|smau|paid_gmau|umau}.freeze
      METRIC_REMOVED = %r{\+status: removed}.freeze
      DATABASE_REGEX = %r{\Adb/structure\.sql}.freeze
      STRUCTURE_SQL_FILE = %w(db/structure.sql).freeze

      def build_message
        return unless impacted?

        CHANGED_SCHEMA_MESSAGE + helper.markdown_list(data_warehouse_impact_files)
      end

      def impacted?
        !labelled_as_datawarehouse? && data_warehouse_impact_files.any?
      end

      private

      def data_warehouse_impact_files
        @impacted_files ||= (metrics_changed_files + database_changed_files)
      end

      def labelled_as_datawarehouse?
        helper.mr_labels.any? { |label| label.start_with?(DATA_WAREHOUSE_SCOPE) }
      end

      def metrics_changed_files
        metrics_definitions_files = helper.modified_files.grep(FILE_PATH_REGEX)

        metrics_definitions_files.select do |file|
          helper.changed_lines(file).any? { |change| performance_indicator_changed?(change) || status_removed?(change) }
        end.compact
      end

      def database_changes?
        !helper.modified_files.grep(DATABASE_REGEX).empty?
      end

      def database_changed_files
        helper.modified_files & STRUCTURE_SQL_FILE
      end

      def performance_indicator_changed?(change)
        change =~ PERFORMANCE_INDICATOR_REGEX
      end

      def status_removed?(change)
        change =~ METRIC_REMOVED
      end
    end
  end
end
