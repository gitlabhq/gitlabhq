# frozen_string_literal: true

module Tooling
  module Danger
    module Documentation
      SOLUTIONS_LABELS = %w[Solutions].freeze
      DEVELOPMENT_LABELS = ['development guidelines'].freeze

      ANY_MAINTAINER_CAN_MERGE_MESSAGE_TEMPLATE = <<~MSG
        This MR contains docs in the /%<directory>s directory, but any Maintainer can merge. You do not need tech writer review.
      MSG

      SOLUTIONS_MESSAGE = <<~MSG
        This MR contains docs in the /doc/solutions directory and should be reviewed by a Solutions Architect approver. You do not need tech writer review.
      MSG

      LOCALIZATION_MESSAGE = <<~MSG
        This MR contains files in the /doc-locale directory. These files are translations maintained through a separate process and should not be edited directly. If you are not part of the Localization team, please remove the changes to these files from your MR.
      MSG

      DOCS_LONG_PIPELINE_MESSAGE = <<~MSG
        This merge request contains documentation files that require a tier-3 code pipeline before merge. After you complete all needed documentation reviews with short docs pipelines, see the [instructions for running a long pipeline](https://docs.gitlab.com/development/documentation/workflow/#pipelines-and-branch-naming) to this merge request.
      MSG

      # For regular pages, prompt for a TW review
      DOCS_UPDATE_SHORT_MESSAGE = <<~MSG
        This merge request adds or changes documentation files and requires Technical Writing review. The review should happen before merge, but can be post-merge if the merge request is time sensitive.
      MSG

      DOCS_UPDATE_LONG_MESSAGE_TEMPLATE = <<~MSG
        ## Documentation review

        The following files require a review from a technical writer:

        %<doc_paths_to_review>s

        The review does not need to block merging this merge request. See the:

        - [Metadata for the `*.md` files](https://docs.gitlab.com/ee/development/documentation/#metadata) that you've changed. The first few lines of each `*.md` file identify the stage and group most closely associated with your docs change.
        - The [Technical Writer assigned](https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments) for that stage and group.
        - [Documentation workflows](https://docs.gitlab.com/development/documentation/workflow/) for information on when to assign a merge request for review.
      MSG

      # Documentation should be updated for feature::addition and feature::enhancement
      DOCUMENTATION_UPDATE_MISSING = <<~MSG
        ~"feature::addition" and ~"feature::enhancement" merge requests normally have a documentation change. Consider adding a documentation update or confirming the documentation plan with the [Technical Writer counterpart](https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments).

        For more information, see:

        - The Handbook page on [merge request types](https://handbook.gitlab.com/handbook/product/groups/product-analysis/engineering/metrics/#work-type-classification).
        - The [definition of done](https://docs.gitlab.com/development/contributing/merge_request_workflow/#definition-of-done) documentation.
      MSG

      # Some docs do not need a review from a Technical Writer.
      # In these cases, we'll output a message specific to the section.
      SECTIONS_WITH_NO_TW_REVIEW = %w[doc/development/ doc/solutions/ doc-locale/].freeze

      # Some docs require a longer pipeline, which cannot be avoided.
      SECTIONS_WITH_TIER3_REVIEW = %w[doc/_index.md doc/api/settings.md].freeze

      # One exception to the exceptions above: Technical Writing docs should get a TW review.
      TW_DOCS_PATH = 'doc/development/documentation'

      def check_documentation
        # Output messages
        warn(DOCUMENTATION_UPDATE_MISSING) if docs_paths_to_review.empty? && feature_mr?

        if sections_with_no_tw_review["doc/development/"].any?
          add_labels(DEVELOPMENT_LABELS)
          message(format(ANY_MAINTAINER_CAN_MERGE_MESSAGE_TEMPLATE, directory: 'doc/development'))
        end

        if sections_with_no_tw_review["doc/solutions/"].any?
          add_labels(SOLUTIONS_LABELS)
          message(SOLUTIONS_MESSAGE)
        end

        if sections_with_no_tw_review["doc-locale/"].any?
          message(LOCALIZATION_MESSAGE, file: sections_with_no_tw_review["doc-locale/"].first, line: 1)
        end

        message(DOCS_LONG_PIPELINE_MESSAGE) if sections_with_tier3_review.values.flatten.any?

        return if docs_paths_to_review.empty?

        message(DOCS_UPDATE_SHORT_MESSAGE)
        markdown(format(
          DOCS_UPDATE_LONG_MESSAGE_TEMPLATE,
          doc_paths_to_review:
            docs_paths_to_review.map do |path|
              "* `#{path}` ([Link to current live version](#{doc_path_to_url(path)}))"
            end.join("\n")
        ))
      end

      private

      def docs_changes
        helper.changes_by_category[:docs]
      end

      def group_docs_by_sections(sections)
        grouped = Hash.new { |h, k| h[k] = [] }

        docs_changes.each do |doc|
          next if doc.start_with?(TW_DOCS_PATH)

          section = sections.find { |prefix| doc.start_with?(prefix) }
          grouped[section] << doc if section
        end

        grouped
      end

      def docs_paths_to_review
        @docs_paths_to_review ||= docs_changes -
          sections_with_no_tw_review.values.flatten -
          sections_with_tier3_review.values.flatten
      end

      def sections_with_no_tw_review
        @sections_with_no_tw_review ||= group_docs_by_sections(SECTIONS_WITH_NO_TW_REVIEW)
      end

      def sections_with_tier3_review
        @sections_with_tier3_review ||= group_docs_by_sections(SECTIONS_WITH_TIER3_REVIEW)
      end

      def feature_mr?
        (helper.mr_labels & %w[feature::addition feature::enhancement]).any?
      end

      def doc_path_to_url(path)
        path.sub(%r{\Adoc/}, "https://docs.gitlab.com/").sub(%r{/_index\.md\z}, "/").sub(%r{\.md\z}, "/")
      end

      def add_labels(labels)
        helper.labels_to_add.concat(labels)
        helper.labels_to_add.push('documentation')
        helper.labels_to_add.push('type::maintenance') unless helper.has_scoped_label_with_scope?('type')
        helper.labels_to_add.push('maintenance::refactor') unless helper.has_scoped_label_with_scope?('maintenance')
      end
    end
  end
end
