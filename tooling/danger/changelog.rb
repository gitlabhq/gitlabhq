# frozen_string_literal: true

require 'gitlab/dangerfiles/title_linting'

module Tooling
  module Danger
    module Changelog
      NO_CHANGELOG_LABELS = [
        'tooling',
        'tooling::pipelines',
        'tooling::workflow',
        'ci-build',
        'meta'
      ].freeze
      NO_CHANGELOG_CATEGORIES = %i[docs none].freeze
      CREATE_CHANGELOG_COMMAND = 'bin/changelog -m %<mr_iid>s "%<mr_title>s"'
      CREATE_EE_CHANGELOG_COMMAND = 'bin/changelog --ee -m %<mr_iid>s "%<mr_title>s"'
      CHANGELOG_MODIFIED_URL_TEXT = "**CHANGELOG.md was edited.** Please remove the additions and create a CHANGELOG entry.\n\n"
      CHANGELOG_MISSING_URL_TEXT = "**[CHANGELOG missing](https://docs.gitlab.com/ee/development/changelog.html)**:\n\n"

      OPTIONAL_CHANGELOG_MESSAGE = {
        local: "If this merge request [doesn't need a CHANGELOG entry](https://docs.gitlab.com/ee/development/changelog.html#what-warrants-a-changelog-entry), feel free to ignore this message.",
        ci: <<~MSG
        If you want to create a changelog entry for GitLab FOSS, run the following:

            #{CREATE_CHANGELOG_COMMAND}

        If you want to create a changelog entry for GitLab EE, run the following instead:

            #{CREATE_EE_CHANGELOG_COMMAND}

        If this merge request [doesn't need a CHANGELOG entry](https://docs.gitlab.com/ee/development/changelog.html#what-warrants-a-changelog-entry), feel free to ignore this message.
        MSG
      }.freeze

      REQUIRED_CHANGELOG_REASONS = {
        feature_flag_removed: 'removes a feature flag'
      }.freeze
      REQUIRED_CHANGELOG_MESSAGE = {
        local: "This merge request requires a changelog entry because it [%<reason>s](https://docs.gitlab.com/ee/development/changelog.html#what-warrants-a-changelog-entry).",
        ci: <<~MSG
        To create a changelog entry, run the following:

            #{CREATE_CHANGELOG_COMMAND}

        This merge request requires a changelog entry because it [%<reason>s](https://docs.gitlab.com/ee/development/changelog.html#what-warrants-a-changelog-entry).
        MSG
      }.freeze

      def required_reasons
        [].tap do |reasons|
          reasons << :feature_flag_removed if project_helper.changes.deleted.has_category?(:feature_flag)
        end
      end

      def required?
        required_reasons.any?
      end

      def optional?
        categories_need_changelog? && without_no_changelog_label?
      end

      def found
        @found ||= project_helper.changes.added.by_category(:changelog).files.first
      end

      def ee_changelog?
        found.start_with?('ee/')
      end

      def modified_text
        CHANGELOG_MODIFIED_URL_TEXT +
          (helper.ci? ? format(OPTIONAL_CHANGELOG_MESSAGE[:ci], mr_iid: helper.mr_iid, mr_title: sanitized_mr_title) : OPTIONAL_CHANGELOG_MESSAGE[:local])
      end

      def required_texts
        required_reasons.each_with_object({}) do |required_reason, memo|
          memo[required_reason] =
            CHANGELOG_MISSING_URL_TEXT +
              (helper.ci? ? format(REQUIRED_CHANGELOG_MESSAGE[:ci], reason: REQUIRED_CHANGELOG_REASONS.fetch(required_reason), mr_iid: helper.mr_iid, mr_title: sanitized_mr_title) : REQUIRED_CHANGELOG_MESSAGE[:local])
        end
      end

      def optional_text
        CHANGELOG_MISSING_URL_TEXT +
          (helper.ci? ? format(OPTIONAL_CHANGELOG_MESSAGE[:ci], mr_iid: helper.mr_iid, mr_title: sanitized_mr_title) : OPTIONAL_CHANGELOG_MESSAGE[:local])
      end

      private

      def sanitized_mr_title
        Gitlab::Dangerfiles::TitleLinting.sanitize_mr_title(helper.mr_title)
      end

      def categories_need_changelog?
        (project_helper.changes.categories - NO_CHANGELOG_CATEGORIES).any?
      end

      def without_no_changelog_label?
        (helper.mr_labels & NO_CHANGELOG_LABELS).empty?
      end
    end
  end
end
