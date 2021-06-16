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
      CHANGELOG_TRAILER_REGEX = /^(?<name>Changelog):\s*(?<category>.+)$/i.freeze
      CHANGELOG_EE_TRAILER_REGEX = /^EE: true$/.freeze
      CHANGELOG_MODIFIED_URL_TEXT = "**CHANGELOG.md was edited.** Please remove the additions and follow the [changelog guidelines](https://docs.gitlab.com/ee/development/changelog.html).\n\n"
      CHANGELOG_MISSING_URL_TEXT = "**[CHANGELOG missing](https://docs.gitlab.com/ee/development/changelog.html)**:\n\n"

      OPTIONAL_CHANGELOG_MESSAGE = {
        local: "If this merge request [doesn't need a CHANGELOG entry](https://docs.gitlab.com/ee/development/changelog.html#what-warrants-a-changelog-entry), feel free to ignore this message.",
        ci: <<~MSG
        If you want to create a changelog entry for GitLab FOSS, add the `Changelog` trailer to the commit message you want to add to the changelog.

        If you want to create a changelog entry for GitLab EE, also [add the `EE: true` trailer](https://docs.gitlab.com/ee/development/changelog.html#gitlab-enterprise-changes) to your commit message.

        If this merge request [doesn't need a CHANGELOG entry](https://docs.gitlab.com/ee/development/changelog.html#what-warrants-a-changelog-entry), feel free to ignore this message.
        MSG
      }.freeze
      SEE_DOC = "See the [changelog documentation](https://docs.gitlab.com/ee/development/changelog.html)."

      REQUIRED_CHANGELOG_REASONS = {
        db_changes: 'introduces a database migration',
        feature_flag_removed: 'removes a feature flag'
      }.freeze
      REQUIRED_CHANGELOG_MESSAGE = {
        local: "This merge request requires a changelog entry because it [%<reason>s](https://docs.gitlab.com/ee/development/changelog.html#what-warrants-a-changelog-entry).",
        ci: <<~MSG
        To create a changelog entry, add the `Changelog` trailer to one of your Git commit messages.

        This merge request requires a changelog entry because it [%<reason>s](https://docs.gitlab.com/ee/development/changelog.html#what-warrants-a-changelog-entry).
        MSG
      }.freeze

      CATEGORIES = YAML
        .load_file(File.expand_path('../../.gitlab/changelog_config.yml', __dir__))
        .fetch('categories')
        .keys
        .freeze

      class ChangelogCheckResult
        attr_reader :errors, :warnings, :markdowns, :messages

        def initialize(errors: [], warnings: [], markdowns: [], messages: [])
          @errors = errors
          @warnings = warnings
          @markdowns = markdowns
          @messages = messages
        end
        private_class_method :new

        def self.empty
          new
        end

        def self.error(error)
          new(errors: [error])
        end

        def self.warning(warning)
          new(warnings: [warning])
        end

        def error(error)
          errors << error
        end

        def warning(warning)
          warnings << warning
        end

        def markdown(markdown)
          markdowns << markdown
        end

        def message(message)
          messages << message
        end
      end

      # rubocop:disable Style/SignalException
      def check!
        if git.modified_files.include?("CHANGELOG.md")
          fail modified_text
        end

        if present?
          add_danger_messages(check_changelog_path)
        elsif required?
          required_texts.each { |_, text| fail(text) } # rubocop:disable Lint/UnreachableLoop
        elsif optional?
          message optional_text
        end

        check_changelog_commit_categories
      end
      # rubocop:enable Style/SignalException

      # rubocop:disable Style/SignalException
      def add_danger_messages(check_result)
        check_result.errors.each { |error| fail(error) } # rubocop:disable Lint/UnreachableLoop
        check_result.warnings.each { |warning| warn(warning) }
        check_result.markdowns.each { |markdown_hash| markdown(**markdown_hash) }
        check_result.messages.each { |text| message(text) }
      end
      # rubocop:enable Style/SignalException

      def check_changelog_commit_categories
        changelog_commits.each do |commit|
          add_danger_messages(check_changelog_trailer(commit))
        end
      end

      def check_changelog_trailer(commit)
        trailer = commit.message.match(CHANGELOG_TRAILER_REGEX)
        name = trailer[:name]
        category = trailer[:category]

        unless name == 'Changelog'
          return ChangelogCheckResult.error("The changelog trailer for commit #{commit.sha} must be `Changelog` (starting with a capital C), not `#{name}`")
        end

        return ChangelogCheckResult.empty if CATEGORIES.include?(category)

        ChangelogCheckResult.error("Commit #{commit.sha} uses an invalid changelog category: #{category}")
      end

      def check_changelog_path
        check_result = ChangelogCheckResult.empty
        return check_result unless present?

        ee_changes = project_helper.all_ee_changes.dup

        if ee_changes.any? && !ee_changelog? && !required?
          check_result.warning("This MR changes code in `ee/`, but its Changelog commit is missing the [`EE: true` trailer](https://docs.gitlab.com/ee/development/changelog.html#gitlab-enterprise-changes). Consider adding it to your Changelog commits.")
        end

        if ee_changes.empty? && ee_changelog?
          check_result.warning("This MR has a Changelog commit for EE, but no code changes in `ee/`. Consider removing the `EE: true` trailer from your commits.")
        end

        if ee_changes.any? && ee_changelog? && required_reasons.include?(:db_changes)
          check_result.warning("This MR has a Changelog commit with the `EE: true` trailer, but there are database changes which [requires](https://docs.gitlab.com/ee/development/changelog.html#what-warrants-a-changelog-entry) the Changelog commit to not have the `EE: true` trailer. Consider removing the `EE: true` trailer from your commits.")
        end

        check_result
      end

      def required_reasons
        [].tap do |reasons|
          reasons << :db_changes if project_helper.changes.added.has_category?(:migration)
          reasons << :feature_flag_removed if project_helper.changes.deleted.has_category?(:feature_flag)
        end
      end

      def required?
        required_reasons.any?
      end

      def optional?
        categories_need_changelog? && mr_without_no_changelog_label?
      end

      def present?
        valid_changelog_commits.any?
      end

      def changelog_commits
        git.commits.select do |commit|
          commit.message.match?(CHANGELOG_TRAILER_REGEX)
        end
      end

      def valid_changelog_commits
        changelog_commits.select do |commit|
          trailer = commit.message.match(CHANGELOG_TRAILER_REGEX)

          CATEGORIES.include?(trailer[:category])
        end
      end

      def ee_changelog?
        changelog_commits.any? do |commit|
          commit.message.match?(CHANGELOG_EE_TRAILER_REGEX)
        end
      end

      def modified_text
        CHANGELOG_MODIFIED_URL_TEXT +
          (helper.ci? ? format(OPTIONAL_CHANGELOG_MESSAGE[:ci]) : OPTIONAL_CHANGELOG_MESSAGE[:local])
      end

      def required_texts
        required_reasons.each_with_object({}) do |required_reason, memo|
          memo[required_reason] =
            CHANGELOG_MISSING_URL_TEXT +
              (helper.ci? ? format(REQUIRED_CHANGELOG_MESSAGE[:ci], reason: REQUIRED_CHANGELOG_REASONS.fetch(required_reason)) : REQUIRED_CHANGELOG_MESSAGE[:local])
        end
      end

      def optional_text
        CHANGELOG_MISSING_URL_TEXT +
          (helper.ci? ? format(OPTIONAL_CHANGELOG_MESSAGE[:ci]) : OPTIONAL_CHANGELOG_MESSAGE[:local])
      end

      private

      def read_file(path)
        File.read(path)
      end

      def categories_need_changelog?
        (project_helper.changes.categories - NO_CHANGELOG_CATEGORIES).any?
      end

      def mr_without_no_changelog_label?
        (helper.mr_labels & NO_CHANGELOG_LABELS).empty?
      end
    end
  end
end
