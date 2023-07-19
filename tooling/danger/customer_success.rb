# frozen_string_literal: true

module Tooling
  module Danger
    module CustomerSuccess
      CHANGED_SCHEMA_MESSAGE = <<~MSG
        Notification to the Customer Success about changes to files with possible breaking downstream processes, add label `Customer Success::Impact Check`.

        /label ~"Customer Success::Impact Check"

        The following files require a review:
      MSG

      FILE_PATH_REGEX = %r{((ee|jh)/)?config/metrics/.+\.yml}
      CATEGORY_CHANGED = /data_category: operational/i

      def build_message
        return unless impacted?

        CHANGED_SCHEMA_MESSAGE + helper.markdown_list(impacted_files)
      end

      private

      def impacted?
        !helper.has_scoped_label_with_scope?('Customer Success') && impacted_files.any?
      end

      def impacted_files
        @impacted_files ||=
          metric_files.select do |file|
            helper.changed_lines(file).any? { |change| metric_category_changed?(change) }
          end.compact
      end

      def metric_files
        helper.modified_files.grep(FILE_PATH_REGEX)
      end

      def metric_category_changed?(change)
        change =~ CATEGORY_CHANGED
      end
    end
  end
end
