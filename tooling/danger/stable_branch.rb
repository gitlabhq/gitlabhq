# frozen_string_literal: true

module Tooling
  module Danger
    module StableBranch
      VersionApiError = Class.new(StandardError)

      STABLE_BRANCH_REGEX = %r{\A(?<version>\d+-\d+)-stable-ee\z}
      FAILING_PACKAGE_AND_TEST_STATUSES = %w[manual canceled].freeze

      # rubocop:disable Lint/MixedRegexpCaptureTypes
      VERSION_REGEX = %r{
        \A(?<major>\d+)
        \.(?<minor>\d+)
        (\.(?<patch>\d+))?
        (-(?<rc>rc(?<rc_number>\d*)))?
        (-\h+\.\h+)?
        (-ee|\.ee\.\d+)?\z
      }x
      # rubocop:enable Lint/MixedRegexpCaptureTypes

      TEMPLATE_SOURCE_REGEX = %r{\s*template\s+sourced\s+from\s+(https?://\S+)}i

      MAINTENANCE_POLICY_URL = 'https://docs.gitlab.com/policy/maintenance/'

      MAINTENANCE_POLICY_MESSAGE = <<~MSG
      See the [release and maintenance policy](#{MAINTENANCE_POLICY_URL}) for more information.
      MSG

      FEATURE_ERROR_MESSAGE = <<~MSG
      This MR includes the `type::feature` label. Features do not qualify for patch releases. #{MAINTENANCE_POLICY_MESSAGE}
      MSG

      BUG_MAINTENANCE_ERROR_MESSAGE = <<~MSG
      This branch is meant for backporting bug fixes, maintenance changes, and flaky spec failures. If this MR qualifies please add the `type::bug`, `type::maintenance` or `failure::flaky-test` label. #{MAINTENANCE_POLICY_MESSAGE}
      MSG

      VERSION_WARNING_MESSAGE = <<~MSG
      Backporting to older releases requires an [exception request process](https://docs.gitlab.com/policy/maintenance/#backporting-to-older-releases)
      MSG

      NONDESCRIPTIVE_TITLE_MESSAGE = <<~MSG
      The MR title needs to be descriptive (e.g. "Backport of 'title of default branch MR'").
      This is important, since the title will be copied to the patch blog post.
      MSG

      FAILED_VERSION_REQUEST_MESSAGE = <<~MSG
      There was a problem checking if this is a qualified version for backporting. Re-running this job may fix the problem.
      MSG

      PIPELINE_EXPEDITED_ERROR_MESSAGE = <<~MSG
      ~"pipeline::expedited" is not allowed on stable branches because it causes the `e2e:test-on-omnibus-ee` job to be skipped.
      MSG

      NEEDS_PACKAGE_AND_TEST_MESSAGE = <<~MSG
      The `e2e:test-on-omnibus-ee` job is not present, has been canceled, or needs to be automatically triggered.
      Please ensure the job is present in the latest pipeline, if necessary, retry the `danger-review` job.
      Read the "QA e2e:test-on-omnibus-ee" section for more details.
      MSG

      WARN_PACKAGE_AND_TEST_MESSAGE = <<~MSG
      **The `e2e:test-on-omnibus-ee` job needs to succeed or have approval from a Software Engineer in Test.**
      Read the "QA e2e:test-on-omnibus-ee" section for more details.
      MSG

      NEEDS_STABLE_BRANCH_TEMPLATE_MESSAGE = <<~MSG
      This backport does not use the [stable branch template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/merge_request_templates/Stable%20Branch.md).
      Please update the merge request description to use the correct template. Steps for backporting a bug fix can be found on the
      [engineer runbook](https://gitlab.com/gitlab-org/release/docs/-/blob/master/general/patch/engineers.md#backporting-a-bug-fix-in-the-gitlab-project)
      MSG

      def check!
        return unless valid_stable_branch?

        fail NEEDS_STABLE_BRANCH_TEMPLATE_MESSAGE unless uses_stable_branch_template?

        fail FEATURE_ERROR_MESSAGE if has_feature_label?
        fail BUG_MAINTENANCE_ERROR_MESSAGE unless stable_branch_fixes_only?

        warn VERSION_WARNING_MESSAGE unless targeting_patchable_version?

        fail NONDESCRIPTIVE_TITLE_MESSAGE if has_default_title?

        return if has_flaky_failure_label? || allowed_backport_changes?

        fail PIPELINE_EXPEDITED_ERROR_MESSAGE if has_pipeline_expedited_label?

        return unless has_tier_3_label?

        status = package_and_test_bridge_and_pipeline_status

        if status.nil? || FAILING_PACKAGE_AND_TEST_STATUSES.include?(status) # rubocop:disable Style/GuardClause
          fail NEEDS_PACKAGE_AND_TEST_MESSAGE
        else
          warn WARN_PACKAGE_AND_TEST_MESSAGE
        end
      end

      def encourage_package_and_qa_execution?
        valid_stable_branch? &&
          !allowed_backport_changes? &&
          !has_flaky_failure_label?
      end

      def valid_stable_branch?
        !!stable_target_branch && !helper.security_mr?
      end

      private

      def package_and_test_bridge_and_pipeline_status
        mr_head_pipeline_id = gitlab.mr_json.dig('head_pipeline', 'id')
        return unless mr_head_pipeline_id

        bridge = package_and_test_bridge(mr_head_pipeline_id)

        return unless bridge

        if bridge['status'] == 'created'
          bridge['status']
        else
          bridge.fetch('downstream_pipeline')&.fetch('status')
        end
      end

      def package_and_test_bridge(mr_head_pipeline_id)
        gitlab
          .api
          .pipeline_bridges(helper.mr_target_project_id, mr_head_pipeline_id)
          &.find { |bridge| bridge['name'] == 'e2e:test-on-omnibus-ee' }
      end

      def stable_target_branch
        helper.mr_target_branch.match(STABLE_BRANCH_REGEX)
      end

      def has_feature_label?
        helper.mr_has_labels?('type::feature')
      end

      def has_bug_label?
        helper.mr_has_labels?('type::bug')
      end

      def has_maintenance_label?
        helper.mr_has_labels?('type::maintenance')
      end

      def has_pipeline_expedited_label?
        helper.mr_has_labels?('pipeline::expedited') ||
          # TODO: Remove once the label is renamed to be scoped
          helper.mr_has_labels?('pipeline:expedite')
      end

      def has_flaky_failure_label?
        helper.mr_has_labels?('failure::flaky-test')
      end

      def stable_branch_fixes_only?
        has_bug_label? || has_maintenance_label? || has_flaky_failure_label?
      end

      def has_tier_3_label?
        helper.mr_has_labels?('pipeline::tier-3')
      end

      def allowed_backport_changes?
        allowed_categories = %i[docs ci_template test]
        categories_changed = helper.changes_by_category.keys

        categories_changed.all? { |category| allowed_categories.include?(category) }
      end

      def targeting_patchable_version?
        raise VersionApiError if maintained_stable_versions.empty?

        maintained_stable_versions.include?(targeted_version)
      rescue VersionApiError
        warn FAILED_VERSION_REQUEST_MESSAGE
        true
      end

      def maintained_stable_versions
        minor_versions.first(3)
      end

      def targeted_version
        stable_target_branch[1].tr('-', '.')
      end

      def minor_versions
        return unless versions

        versions
          .filter_map { |version| version.match(VERSION_REGEX) }
          .uniq { |matched_version| "#{matched_version[:major]}.#{matched_version[:minor]}" }
          .map { |uniq_version| version_to_minor_string(uniq_version) }
      end

      def versions(page = 1)
        version_api_endpoint = "https://version.gitlab.com/api/v1/versions?per_page=20&page=#{page}"
        response = HTTParty.get(version_api_endpoint) # rubocop:disable Gitlab/HTTParty

        raise VersionApiError unless response.success?

        version_list = response.parsed_response.map { |v| v['version'] }

        version_list.sort_by { |v| Gem::Version.new(v) }.reverse
      end

      def version_to_minor_string(version)
        "#{version[:major]}.#{version[:minor]}"
      end

      def template_source_path
        helper.mr_description.scan(TEMPLATE_SOURCE_REGEX).flatten.first
      end

      def uses_stable_branch_template?
        template_source_path&.include?('.gitlab/merge_request_templates/Stable%20Branch.md')
      end

      def has_default_title?
        title = helper.mr_title
        pattern = /\AMerge branch '([^']+)' into '([^']+)'\z/

        title.match?(pattern)
      end
    end
  end
end
