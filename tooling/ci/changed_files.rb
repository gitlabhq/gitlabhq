#!/usr/bin/env ruby
# frozen_string_literal: true

module CI
  class ChangedFiles
    FRONTEND_FILES_FILTER = /\.(js|cjs|mjs|vue)$/

    def initialize(env: ENV, args: ARGV)
      @env = env
      @args = args
    end

    private attr_reader :env, :args

    def should_run_checks_for_changed_files
      is_valid_mr_event = env['CI_PIPELINE_SOURCE'] == 'merge_request_event' &&
        env['CI_MERGE_REQUEST_EVENT_TYPE'] != 'merge_train'

      labels = env['CI_MERGE_REQUEST_LABELS']

      is_tier_1_pipeline = labels.nil? || labels.include?('pipeline::tier-1')

      is_not_master_branch = env['CI_COMMIT_REF_NAME'] != env['CI_DEFAULT_BRANCH']

      is_valid_mr_event && is_tier_1_pipeline && is_not_master_branch
    end

    # See: https://gitlab.com/groups/gitlab-org/-/epics/16845#note_2370956250
    # for why we use `HEAD~` to compare
    def get_changed_files_in_merged_results_pipeline
      `git diff --name-only --diff-filter=d HEAD~..HEAD`.split("\n")
    end

    def filter_and_get_changed_files_in_mr(filter_pattern: //)
      changed_files =
        if should_run_checks_for_changed_files
          get_changed_files_in_merged_results_pipeline.grep(filter_pattern)
        else
          puts "Changed file criteria didn't match... Command will run for all files"
          ['.']
        end

      puts 'No files were changed. Skipping...' if changed_files.empty?

      changed_files
    end

    def run_eslint_for_changed_files
      puts 'Running ESLint...'
      files = filter_and_get_changed_files_in_mr(filter_pattern: FRONTEND_FILES_FILTER)

      return 0 if files.empty?

      command = ["yarn", "run", "lint:eslint", "--no-warn-ignored", "--format", "gitlab", *files]
      system(*command)

      last_command_status.exitstatus
    end

    def last_command_status
      $?
    end

    def process_command_and_determine_exit_status
      return 0 if args.empty?

      command = args.first

      case command
      when "eslint"
        run_eslint_for_changed_files
      else
        warn "Unknown command: #{command}"
        1
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  runner = CI::ChangedFiles.new
  exit runner.process_command_and_determine_exit_status
end
