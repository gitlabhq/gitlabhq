# frozen_string_literal: true

module Tooling
  module Danger
    module ContainerQueries
      EXCLUSION_LIST_PATH = "../../scripts/frontend/lib/container_queries_migration_exclusions.txt"
      EXPANDED_PATH = File.expand_path(EXCLUSION_LIST_PATH, __dir__)
      UNEXPECTED_CQS_MESSAGE =
        "This merge request changed files which contain container queries and probably shouldn't."
      UNEXPECTED_MQS_MESSAGE =
        "This merge request changed files which contain media queries and probably shouldn't."

      def check
        exclusion_list = File.read(EXPANDED_PATH).split("\n").select { |str| !str.start_with?('#') && !str.empty? }

        files_with_unexpected_cqs = get_files_with_unexpected_cqs(helper.all_changed_files, exclusion_list)
        files_with_unexpected_mqs = get_files_with_unexpected_mqs(helper.all_changed_files, exclusion_list)

        if files_with_unexpected_cqs.any?
          warn UNEXPECTED_CQS_MESSAGE

          markdown(<<~MARKDOWN)
            ## Unexpected container queries

            The following files contain container queries despite being flagged as not needing them.
            Please make sure you haven't wrongfully added container queries in those:

            #{files_with_unexpected_cqs.map { |path| "  * `#{path}`" }.join("\n")}
          MARKDOWN
        end

        return unless files_with_unexpected_mqs.any?

        warn UNEXPECTED_MQS_MESSAGE

        markdown(<<~MARKDOWN)
            ## Unexpected media queries

            The following files contain media queries despite being flagged as not needing them.
            Please make sure you haven't wrongfully added media queries in those:

            #{files_with_unexpected_mqs.map { |path| "  * `#{path}`" }.join("\n")}
        MARKDOWN
      end

      private

      def filter_files_by_pattern(files, exclusion_list, regex, exclude_files: true)
        files.select do |file|
          file_matches_exclusion = exclusion_list.any? { |pattern| file.match pattern }

          should_include_file = exclude_files ? file_matches_exclusion : !file_matches_exclusion

          should_include_file &&
            file.end_with?('.vue', '.js', '.haml', '.rb', '.erb') &&
            regex.match?(helper.git.diff_for_file(file).patch)
        end
      end

      def get_files_with_unexpected_cqs(files, exclusion_list)
        filter_files_by_pattern(files, exclusion_list, %r{@(max-)?(xs|sm|md|lg|xl)(/\w+)?:gl-}, exclude_files: true)
      end

      def get_files_with_unexpected_mqs(files, exclusion_list)
        filter_files_by_pattern(files, exclusion_list, /[^@]?(max-)?(xs|sm|md|lg|xl):gl-/, exclude_files: false)
      end
    end
  end
end
