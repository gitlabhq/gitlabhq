# frozen_string_literal: true

module Tooling
  module Danger
    module CiJobsDependencyValidation
      VALIDATED_JOB_NAMES = %w[setup-test-env compile-test-assets retrieve-tests-metadata build-gdk-image].freeze
      GLOBAL_KEYWORDS = %w[workflow variables stages default].freeze
      DEFAULT_BRANCH_NAME = 'master'

      Job = Struct.new(:name, :rules, :needs, keyword_init: true) do
        def self.parse_rules_from_yaml(name, jobs_yaml)
          attribute_values(jobs_yaml, name, 'rules').filter_map do |rule|
            next if rule['when'] == 'manual' || rule['when'] == 'never'

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
          # hidden jobs are extended by other jobs thus their rules will be verified in the extending jobs
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

        VALIDATED_JOB_NAMES.filter_map do |needed_job_name|
          construct_warning_message(needed_job_name)
        end.join("\n")
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

        YAML.load(api_response['merged_yaml'], aliases: true)
      rescue StandardError => e
        puts e.message
        []
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

      def construct_warning_message(needed_job_name)
        needed_job_in_source_branch = source_branch_jobs.find { |job| job.name == needed_job_name }
        needed_job_in_target_branch = target_branch_jobs.find { |job| job.name == needed_job_name }

        if needed_job_in_source_branch.nil?
          return "Unable to find job #{needed_job_name} in #{source_branch}. Skipping."
        end

        puts "Looking for misconfigured dependent jobs for #{needed_job_name}..."

        warnings = changed_jobs_warnings(
          needed_job_in_source_branch: needed_job_in_source_branch,
          needed_job_in_target_branch: needed_job_in_target_branch
        )

        puts "Detected #{warnings.count} dependent jobs with misconfigured rules."

        return if warnings.empty?

        <<~MSG
          **This MR adds new rules to the following dependent jobs for `#{needed_job_name}`:**

          #{warnings.join("\n")}

          Please ensure the changes are included in the rules for `#{needed_job_name}` to avoid yaml syntax error!

          <details><summary>Click to expand rules for #{needed_job_name} to confirm if the new conditions are present</summary>

          ```yaml
          #{dump_yaml(needed_job_in_source_branch.rules)}
          ```

          </details>
        MSG
      end

      def changed_jobs_warnings(needed_job_in_source_branch:, needed_job_in_target_branch:)
        dependent_jobs_new = needed_job_in_source_branch&.dependent_jobs(source_branch_jobs) || []
        dependent_jobs_old = needed_job_in_target_branch&.dependent_jobs(target_branch_jobs) || []

        (dependent_jobs_new - dependent_jobs_old).filter_map do |dependent_job_with_rule_change|
          dependent_job_old = dependent_jobs_old.find do |target_branch_job|
            target_branch_job.name == dependent_job_with_rule_change.name
          end

          report_candidates = if dependent_job_old.nil?
                                dependent_job_with_rule_change.rules
                              else
                                dependent_job_with_rule_change.rules - dependent_job_old.rules
                              end

          puts "Detected #{report_candidates.count} jobs with applicable rule changes."

          rules_to_report = exact_rules_missing_in_needed_job(
            needed_job: needed_job_in_source_branch,
            rules: report_candidates
          )

          next if rules_to_report.empty?

          <<~MARKDOWN.chomp
          `#{dependent_job_with_rule_change.name}`:

          ```yaml
          #{dump_yaml(rules_to_report)}
          ```
          MARKDOWN
        end
      end

      def dump_yaml(yaml)
        YAML.dump(yaml).delete_prefix("---\n").chomp
      end

      # Limitation: "exact" rules missing does not always mean the needed_job is missing the rules
      # needed_jobs can have very generic rules, for example
      #   - rule-for-job1:
      #   - <<: *if-merge-request-targeting-stable-branch
      # - rule-for-needed_job:
      #   - <<: *if-merge-request-targeting-all-branches
      # The above config is still valid, but danger will still print a warning because the exact rule is missing.
      # We will have to manually identify that this config is fine and the warning should be ignored.
      def exact_rules_missing_in_needed_job(rules:, needed_job:)
        return [] if rules.empty?

        rules.select { |rule| !needed_job.rules.include?(rule) }
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
