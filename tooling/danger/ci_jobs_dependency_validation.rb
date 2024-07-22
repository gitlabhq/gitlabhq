# frozen_string_literal: true

module Tooling
  module Danger
    module CiJobsDependencyValidation
      VALIDATED_JOB_NAMES = %w[
        setup-test-env
        compile-test-assets
        retrieve-tests-metadata
        build-gdk-image
        build-assets-image
        build-qa-image
        e2e-test-pipeline-generate
      ].freeze
      GLOBAL_KEYWORDS = %w[workflow variables stages default].freeze
      DEFAULT_BRANCH_NAME = 'master'
      FAILED_VALIDATION_WARNING = 'Please review warnings in the *CI Jobs Dependency Validation* section below.'
      SKIPPED_VALIDATION_WARNING = 'Job dependency validation is skipped due to error fetching merged CI yaml'
      VALIDATION_PASSED_OUTPUT = ':white_check_mark: No warnings found in ci job dependencies.'

      Job = Struct.new(:name, :rules, :needs, keyword_init: true) do
        def self.parse_rules_from_yaml(name, jobs_yaml)
          attribute_values(jobs_yaml, name, 'rules').filter_map do |rule|
            rule.is_a?(Hash) ? rule.slice('if', 'changes', 'when') : rule
          end
        end

        def self.parse_needs_from_yaml(name, jobs_yaml)
          attribute_values(jobs_yaml, name, 'needs').map { |need| need.is_a?(Hash) ? need['job'] : need }
        end

        def self.attribute_values(jobs_yaml, name, attribute)
          return [] if jobs_yaml.nil? || jobs_yaml.empty? || !jobs_yaml[name].is_a?(Hash)

          values = jobs_yaml.dig(name, attribute)
          values.nil? ? [] : Array(values).flatten
        end

        def self.ignore?(job_name)
          GLOBAL_KEYWORDS.include?(job_name) || job_name.start_with?('.')
        end

        def dependent_jobs(jobs)
          jobs.select do |job|
            !Job.ignore?(job.name) && job.needs.include?(name)
          end
        end
      end

      def output_message
        return '' if !helper.ci? || !helper.has_ci_changes? || target_branch_jobs.empty? || source_branch_jobs.empty?

        validation_statuses = VALIDATED_JOB_NAMES.to_h do |job_name|
          [job_name, { skipped: false, failed: 0 }]
        end

        output = VALIDATED_JOB_NAMES.filter_map do |needed_job_name|
          validate(needed_job_name, validation_statuses)
        end.join("\n").chomp

        return VALIDATION_PASSED_OUTPUT if output == ''

        warn FAILED_VALIDATION_WARNING

        <<~MARKDOWN
        ### CI Jobs Dependency Validation

        | name | validation status |
        | ------ | --------------- |
        #{construct_summary_table(validation_statuses)}

        #{output}
        MARKDOWN
      end

      private

      def target_branch_jobs
        @target_branch_jobs ||= build_jobs_from_yaml(target_branch_jobs_yaml, target_branch)
      end

      def source_branch_jobs
        @source_branch_jobs ||= build_jobs_from_yaml(source_branch_jobs_yaml, source_branch)
      end

      def target_branch_jobs_yaml
        @target_branch_jobs_yaml ||= fetch_jobs_yaml(target_project_id, target_branch)
      end

      def source_branch_jobs_yaml
        @source_branch_jobs_yaml ||= fetch_jobs_yaml(source_project_id, source_branch)
      end

      def fetch_jobs_yaml(project_id, ref)
        api_response = gitlab.api.get(lint_path(project_id), query: query_params(ref))

        raise api_response['errors'].first if api_response['merged_yaml'].nil? && api_response['errors']&.any?

        YAML.load(api_response['merged_yaml'], aliases: true)
      rescue StandardError => e
        warn "#{SKIPPED_VALIDATION_WARNING}: #{e.message}"
        {}
      end

      def build_jobs_from_yaml(jobs_yaml, ref)
        puts "Initializing #{jobs_yaml.keys.count} jobs from #{ref} ci config..."

        jobs_yaml.filter_map do |job_name, _job_data|
          next if Job.ignore?(job_name)

          Job.new(
            name: job_name,
            rules: Job.parse_rules_from_yaml(job_name, jobs_yaml),
            needs: Job.parse_needs_from_yaml(job_name, jobs_yaml)
          )
        end
      end

      def query_params(ref)
        ref_query_params = {
          content_ref: ref,
          dry_run_ref: ref,
          include_jobs: true,
          dry_run: true
        }

        ref == DEFAULT_BRANCH_NAME ? {} : ref_query_params
      end

      def validate(needed_job_name, validation_statuses)
        needed_job_in_source_branch = source_branch_jobs.find { |job| job.name == needed_job_name }
        needed_job_in_target_branch = target_branch_jobs.find { |job| job.name == needed_job_name }

        if needed_job_in_source_branch.nil?
          validation_statuses[needed_job_name][:skipped] = true

          return <<~MARKDOWN
          - :warning: Unable to find job `#{needed_job_name}` in branch `#{source_branch}`.
            If this job has been removed, please delete it from `Tooling::Danger::CiJobsDependencyValidation::VALIDATED_JOB_NAMES`.
            Validation skipped.
          MARKDOWN
        end

        failures = validation_failures(
          needed_job_in_source_branch: needed_job_in_source_branch,
          needed_job_in_target_branch: needed_job_in_target_branch
        )

        failed_count = failures.count

        return if failed_count == 0

        validation_statuses[needed_job_name][:failed] = failed_count

        <<~MSG
          - 🚨 **These rule changes do not match with rules for `#{needed_job_name}`:**

          <details><summary>Click to expand details</summary>

          #{failures.join("\n")}
          Here are the rules for `#{needed_job_name}`:

          ```yaml
          #{dump_yaml(needed_job_in_source_branch.rules)}
          ```

          </details>

          To avoid CI config errors, please verify if the same rule addition/removal should be applied to `#{needed_job_name}`.
          If not, please add a comment to explain why.
        MSG
      end

      def construct_summary_table(validation_statuses)
        validation_statuses.map do |job_name, statuses|
          skipped, failed_count = statuses.values_at(:skipped, :failed)

          summary = if skipped
                      ":warning: Skipped"
                    elsif failed_count == 0
                      ":white_check_mark: Passed"
                    else
                      "🚨 Failed (#{failed_count})"
                    end

          <<~MARKDOWN.chomp
          | `#{job_name}` | #{summary} |
          MARKDOWN
        end.join("\n")
      end

      def validation_failures(needed_job_in_source_branch:, needed_job_in_target_branch:)
        dependent_jobs_new = needed_job_in_source_branch&.dependent_jobs(source_branch_jobs) || []
        dependent_jobs_old = needed_job_in_target_branch&.dependent_jobs(target_branch_jobs) || []

        (dependent_jobs_new - dependent_jobs_old).filter_map do |dependent_job_with_rule_change|
          dependent_job_old = dependent_jobs_old.find do |target_branch_job|
            target_branch_job.name == dependent_job_with_rule_change.name
          end

          new_rules = dependent_job_with_rule_change.rules
          old_rules = dependent_job_old&.rules

          added_rules_to_report = rules_missing_in_needed_job(
            needed_job: needed_job_in_source_branch,
            rules: dependent_job_old.nil? ? new_rules : new_rules - old_rules # added rules
          )

          removed_rules_to_report = removed_negative_rules_present_in_needed_job(
            needed_job: needed_job_in_source_branch,
            rules: dependent_job_old.nil? ? [] : old_rules - new_rules # removed rules
          )

          next if added_rules_to_report.empty? && removed_rules_to_report.empty?

          <<~MARKDOWN
          `#{dependent_job_with_rule_change.name}`:

          - Added rules:

          #{report_yaml_markdown(added_rules_to_report)}

          - Removed rules:

          #{report_yaml_markdown(removed_rules_to_report)}
          MARKDOWN
        end
      end

      def report_yaml_markdown(rules_to_report)
        return '`N/A`' unless rules_to_report.any?

        <<~MARKDOWN.chomp
        ```yaml
        #{dump_yaml(rules_to_report)}
        ```
        MARKDOWN
      end

      def dump_yaml(yaml)
        YAML.dump(yaml).delete_prefix("---\n").chomp
      end

      # Limitation: missing rules in needed jobs does not always mean the config is invalid.
      # needed_jobs can have very generic rules, for example
      #   - rule-for-job1:
      #   - <<: *if-merge-request-targeting-stable-branch
      # - rule-for-needed_job:
      #   - <<: *if-merge-request-targeting-all-branches
      # The above config is still valid, but danger will still print a warning because the exact rule is missing.
      # We will have to manually identify that this config is fine and the warning should be ignored.
      def rules_missing_in_needed_job(rules:, needed_job:)
        return [] if rules.empty?

        rules.select do |rule|
          !needed_job.rules.include?(rule) && !negative_rule?(rule)
        end
      end

      def removed_negative_rules_present_in_needed_job(rules:, needed_job:)
        return [] if rules.empty?

        rules.select do |rule|
          needed_job.rules.include?(rule) && negative_rule?(rule)
        end
      end

      def negative_rule?(rule)
        rule.is_a?(Hash) && rule['when'] == 'never'
      end

      def lint_path(project_id)
        "/projects/#{project_id}/ci/lint"
      end

      def source_project_id
        helper.mr_source_project_id
      end

      def target_project_id
        helper.mr_target_project_id
      end

      def source_branch
        helper.mr_source_branch
      end

      def target_branch
        helper.mr_target_branch
      end
    end
  end
end
