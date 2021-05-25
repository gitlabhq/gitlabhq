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
      CHANGELOG_TRAILER_REGEX = /^Changelog:\s*(?<category>.+)$/.freeze
      CREATE_CHANGELOG_COMMAND = 'bin/changelog -m %<mr_iid>s "%<mr_title>s"'
      CREATE_EE_CHANGELOG_COMMAND = 'bin/changelog --ee -m %<mr_iid>s "%<mr_title>s"'
      CHANGELOG_MODIFIED_URL_TEXT = "**CHANGELOG.md was edited.** Please remove the additions and follow the [changelog guidelines](https://docs.gitlab.com/ee/development/changelog.html).\n\n"
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
      CHANGELOG_NEW_WORKFLOW_MESSAGE = <<~MSG
        We are in the process of rolling out a new workflow for adding changelog entries. This new workflow uses Git commit subjects and Git trailers to generate changelogs. This new approach will soon replace the current YAML based approach.

        To ease the transition process, we recommend you start using both the old and new approach in parallel. This is not required at this time, but will make it easier to transition to the new approach in the future. To do so, pick the commit that should go in the changelog and add a `Changelog` trailer to it.  For example:

        ```
        This is my commit's subject line

        This is the optional commit body.

        Changelog: added
        ```

        The value of the `Changelog` trailer should be one of the following: added, fixed, changed, deprecated, removed, security, performance, other.

        For more information, take a look at the following resources:

        - `https://gitlab.com/gitlab-com/gl-infra/delivery/-/issues/1564`
        - https://docs.gitlab.com/ee/api/repositories.html#generate-changelog-data

        If you'd like to see the new approach in action, take a look at the commits in [the Omnibus repository](https://gitlab.com/gitlab-org/omnibus-gitlab/-/commits/master).
      MSG
      SEE_DOC = "See the [changelog documentation](https://docs.gitlab.com/ee/development/changelog.html)."
      SUGGEST_MR_COMMENT = <<~SUGGEST_COMMENT
      ```suggestion
      merge_request: %<mr_iid>s
      ```

      #{SEE_DOC}
      SUGGEST_COMMENT

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
          add_danger_messages(check_changelog_yaml)
          add_danger_messages(check_changelog_path)
        elsif required?
          required_texts.each { |_, text| fail(text) } # rubocop:disable Lint/UnreachableLoop
        elsif optional?
          message optional_text
        end

        return unless helper.ci?

        if required? || optional?
          checked = 0

          git.commits.each do |commit|
            check_result = check_changelog_trailer(commit)
            next if check_result.nil?

            checked += 1
            add_danger_messages(check_result)
          end

          if checked == 0
            message CHANGELOG_NEW_WORKFLOW_MESSAGE
          end
        end
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

      def check_changelog_trailer(commit)
        trailer = commit.message.match(CHANGELOG_TRAILER_REGEX)

        return if trailer.nil? || trailer[:category].nil?

        category = trailer[:category]

        return ChangelogCheckResult.empty if CATEGORIES.include?(category)

        ChangelogCheckResult.error("Commit #{commit.sha} uses an invalid changelog category: #{category}")
      end

      def check_changelog_yaml
        check_result = ChangelogCheckResult.empty
        return check_result unless present?

        raw_file = read_file(changelog_path)
        yaml = YAML.safe_load(raw_file)
        yaml_merge_request = yaml["merge_request"].to_s

        check_result.error("`title` should be set, in #{helper.html_link(changelog_path)}! #{SEE_DOC}") if yaml["title"].nil?
        check_result.error("`type` should be set, in #{helper.html_link(changelog_path)}! #{SEE_DOC}") if yaml["type"].nil?

        return check_result if helper.security_mr? || helper.mr_iid.empty?

        check_changelog_yaml_merge_request(raw_file: raw_file, yaml_merge_request: yaml_merge_request, check_result: check_result)
      rescue Psych::Exception
        # YAML could not be parsed, fail the build.
        ChangelogCheckResult.error("#{helper.html_link(changelog_path)} isn't valid YAML! #{SEE_DOC}")
      rescue StandardError => e
        ChangelogCheckResult.warning("There was a problem trying to check the Changelog. Exception: #{e.class.name} - #{e.message}")
      end

      def check_changelog_yaml_merge_request(raw_file:, yaml_merge_request:, check_result:)
        cherry_pick_against_stable_branch = helper.cherry_pick_mr? && helper.stable_branch?

        if yaml_merge_request.empty?
          mr_line = raw_file.lines.find_index { |line| line =~ /merge_request:\s*\n/ }

          if mr_line
            check_result.markdown(msg: format(SUGGEST_MR_COMMENT, mr_iid: helper.mr_iid), file: changelog_path, line: mr_line.succ)
          else
            check_result.message("Consider setting `merge_request` to #{helper.mr_iid} in #{helper.html_link(changelog_path)}. #{SEE_DOC}")
          end
        elsif yaml_merge_request != helper.mr_iid && !cherry_pick_against_stable_branch
          check_result.error("Merge request ID was not set to #{helper.mr_iid}! #{SEE_DOC}")
        end

        check_result
      end

      def check_changelog_path
        check_result = ChangelogCheckResult.empty
        return check_result unless present?

        ee_changes = project_helper.all_ee_changes.dup
        ee_changes.delete(changelog_path)

        if ee_changes.any? && !ee_changelog? && !required?
          check_result.warning("This MR has a Changelog file outside `ee/`, but code changes in `ee/`. Consider moving the Changelog file into `ee/`.")
        end

        if ee_changes.empty? && ee_changelog?
          check_result.warning("This MR has a Changelog file in `ee/`, but no code changes in `ee/`. Consider moving the Changelog file outside `ee/`.")
        end

        check_result
      end

      def required_reasons
        [].tap do |reasons|
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
        !!changelog_path
      end

      def ee_changelog?
        changelog_path.start_with?('ee/')
      end

      def changelog_path
        @changelog_path ||= project_helper.changes.added.by_category(:changelog).files.first
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

      def read_file(path)
        File.read(path)
      end

      def sanitized_mr_title
        Gitlab::Dangerfiles::TitleLinting.sanitize_mr_title(helper.mr_title)
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
