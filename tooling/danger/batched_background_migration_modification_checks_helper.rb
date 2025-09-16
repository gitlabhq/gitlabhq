# frozen_string_literal: true

require_relative 'ast_parser'
require 'gitlab/utils/upgrade_path'
require 'gitlab/version_info'
require 'open3'
require 'shellwords'
require 'active_support/core_ext/object/blank'

# This module checks if the modified or deleted batched background migration
# has a corresponding finalized migration and the next required stop has been reached.

module Tooling
  module Danger
    module BatchedBackgroundMigrationModificationChecksHelper
      # Match files in the gitlab/background_migration/ OR
      # ee/lib/ee/gitlab/background_migration directories
      # and reject spec/test files
      BATCHED_BACKGROUND_MIGRATION_MATCHER = %r{(?:^|/)(?:ee/lib/ee/)?gitlab/background_migration/(?!.*(spec|test))}

      POST_MIGRATE_DIRECTORIES = [
        'db/post_migrate',
        'ee/db/post_migrate',
        'ee/db/geo/post_migrate'
      ].freeze

      DB_DOC_BBM_DIRECTORY = [
        'db/docs/batched_background_migrations'
      ].freeze

      DOCUMENTATION = "https://docs.gitlab.com/development/database/batched_background_migrations/#deleting-batched-background-migration-code"

      MISSING_FINALIZED_MIGRATION = <<~MESSAGE
      This code can only be modified or deleted after BOTH conditions are met:
      the finalized migration has been completed (and not re-queued) AND after
      the next required stop has been reached.
      MESSAGE

      BEFORE_NEXT_REQUIRED_STOP = <<~MESSAGE
      This code can only be modified or deleted after the next required stop if the finalized
      migration has not been re-queued:
      MESSAGE

      ERROR_MESSAGE = <<~MESSAGE
        The following migration(s) cannot be modified or deleted yet. \
        Please see [deleting batched background migration code](%s) \
        for more information.\n\n%s
      MESSAGE

      def ast_parser(file_content)
        AstParser.new(file_content)
      end

      def find_migrations(changed_files)
        # Filter to only include batched background migration files
        feature_branch_files = changed_files.select { |f| f.match?(BATCHED_BACKGROUND_MIGRATION_MATCHER) }

        return if feature_branch_files.empty?

        # Extract class or modules names from the migration files in PascalCase
        feature_branch_migration_class_names = find_class_or_module_names(feature_branch_files)

        # Check which migrations can be modified or deleted
        unremovable_migrations = find_unremovable_migrations(feature_branch_migration_class_names)

        display_unremovable_migrations(unremovable_migrations.flatten) unless unremovable_migrations.empty?
      end

      def find_class_or_module_names(batched_background_files)
        files_array = Array(batched_background_files)
        class_or_module_name_to_file = {}

        files_array.select { |file_path| file_path.end_with?('.rb') }
                   .each do |file_path|
          file_content = File.read(file_path)

          name = ast_parser(file_content).extract_class_or_module_name

          # Only add to hash if class or module name was successfully extracted
          class_or_module_name_to_file[name] = file_path if name
        rescue StandardError => e
          warn "Failed to extract class name from #{file_path}: #{e.message}"
        end

        # class_or_module_name_to_file => {"AlterWebhookDeletedAuditEvent"=>"lib/gitlab/background_migration/" \
        # alter_webhook_deleted_audit_event.rb",
        #  "BackfillIssueTrackerDataShardingKey"=> "lib/gitlab/background_migration/" \
        # backfill_issue_tracker_data_sharding_key.rb"}
        class_or_module_name_to_file
      end

      def find_unremovable_migrations(migration_class_names)
        # Categorize migrations based on YAML documentation
        finalized_migrations, unremovable_migrations =
          categorize_batched_background_migrations(migration_class_names)

        final_results = []
        final_results << unremovable_migrations unless unremovable_migrations.empty?

        # For finalized migrations, check version requirements
        if finalized_migrations.any?
          # Find finalized migration files
          bbms_and_finalized_files = find_finalized_migration_files(finalized_migrations)

          # Check version requirements
          migrations_before_required_stop = find_unremovable_bbms(bbms_and_finalized_files)
          final_results << migrations_before_required_stop unless migrations_before_required_stop.empty?
        end

        final_results
      end

      # Search through the YAML files and categorize BBM migrations as finalized or unremovable
      # In the case of finalized migrations, we're expecting the
      # finalized_by field in db/docs/batched_background_migrations to have a timestamp:
      # Example:
      # ...
      # finalized_by: '20241103232325'
      def categorize_batched_background_migrations(migration_class_names)
        finalized_migrations = {}
        unremovable_migrations = []

        yaml_files = DB_DOC_BBM_DIRECTORY.flat_map { |dir| Dir.glob(File.join(dir, "*.yml")) }

        yaml_files.each do |file_path|
          yaml_content_raw = File.read(file_path)
          yaml_content = YAML.safe_load(yaml_content_raw, permitted_classes: [], aliases: false)
          next unless yaml_content.is_a?(Hash)

          migration_job_name = yaml_content["migration_job_name"]
          next unless migration_class_names.key?(migration_job_name)

          finalized_by = yaml_content["finalized_by"]

          if finalized_by.to_s.match?(/\A\d{14}\z/)
            # Migration is finalized with a timestamp
            finalized_migrations[migration_job_name] ||= []
            finalized_migrations[migration_job_name] << {
              background_migration_class_name: migration_class_names[migration_job_name],
              finalized_migration_timestamp: finalized_by.to_s
            }
          else
            # Migration is not finalized yet
            unremovable_migrations << {
              batched_background_migration_file: migration_class_names[migration_job_name],
              comment: MISSING_FINALIZED_MIGRATION
            }
          end
        rescue StandardError => e
          warn "Failed to parse YAML file #{file_path}: #{e.message}"
        end

        # finalized_migrations =>=> {"AlterWebhookDeletedAuditEvent"=>
        #   [{:background_migration_class_name=>"lib/gitlab/background_migration/alter_webhook_deleted_audit_event.rb",
        #     :finalized_migration_timestamp=>"20250213231656"}]}
        #
        # unremovable_migrations =>
        # [{:batched_background_migration_file=>"lib/gitlab/background_migration/" \
        # backfill_issue_tracker_data_sharding_key.rb",
        # :comment=>"This code can only be modified..."}]
        [finalized_migrations, unremovable_migrations]
      end

      def find_finalized_migration_files(finalized_migrations)
        return {} if finalized_migrations.empty?

        finalized_files = {}
        timestamps = finalized_migrations.map { |_, data| data.first[:finalized_migration_timestamp] }

        finalized_migration_files = POST_MIGRATE_DIRECTORIES.flat_map do |directory|
          Dir.glob(File.join(directory, "**/{#{timestamps.join(',')}}*.rb"))
        end

        finalized_migration_files.each do |file_path|
          file_content = File.read(file_path)
          parser = ast_parser(file_content)

          next unless parser.has_ensure_batched_background_migration_is_finished_call?

          matching_classes = finalized_migrations.keys.filter do |class_name|
            parser.contains_class_name_assignment?(class_name)
          end

          next if matching_classes.empty?

          milestone = parser.extract_milestone

          matching_classes.each do |name|
            finalized_files[name] ||= []
            finalized_files[name] << {
              batched_background_migration_file: finalized_migrations[name][0][:background_migration_class_name],
              finalized_migration_file: file_path,
              finalized_migration_milestone: milestone
            }
          end
        rescue StandardError => e
          warn "Could not process file #{file_path}: #{e.message}"
        end

        # finalized_files => {"FixCorruptedScannerIdsOfVulnerabilityReads"=>
        #    [{:batched_background_migration_file=>"ee/lib/ee/gitlab/background_migration/
        # fix_corrupted_scanner_ids_of_vulnerability_reads.rb",
        #      :finalized_migration_file=>"db/post_migrate/
        # 20240523045216_finalize_fix_corrupted_scanner_ids_of_vulnerability_reads.rb",
        #      :finalized_migration_milestone=>"17.1"}]}
        finalized_files
      end

      def find_unremovable_bbms(finalized_migrations)
        unremovable_migrations = []
        current_gitlab_version = execute_git_command(
          'show', "origin/#{Shellwords.escape(target_branch)}:VERSION"
        )

        finalized_migrations.each_value do |migration|
          migration.each do |info|
            milestone = info[:finalized_migration_milestone]

            next unless milestone

            begin
              current_milestone = Gitlab::Utils::UpgradePath.new([],
                Gitlab::VersionInfo.parse_from_milestone(milestone))

              next_required_stop = current_milestone.next_required_stop
              migration_can_be_removed = if current_gitlab_version[:success] && current_gitlab_version[:output].present?
                                           version = Gitlab::VersionInfo.parse(current_gitlab_version[:output])
                                           version > next_required_stop
                                         else
                                           false
                                         end

              next if migration_can_be_removed

              # Add to unremovable migrations if it can't be removed
              unremovable_migrations << {
                batched_background_migration_file: info[:batched_background_migration_file],
                finalized_migration_file: info[:finalized_migration_file],
                finalized_migration_milestone: milestone,
                next_required_stop: next_required_stop.to_s,
                current_gitlab_version: current_gitlab_version[:output],
                comment: BEFORE_NEXT_REQUIRED_STOP
              }
            rescue StandardError => e
              warn "Failed to process milestone #{milestone} for #{info[:finalized_migration_file]}: #{e.message}"
              unremovable_migrations << {
                batched_background_migration_file: info[:batched_background_migration_file],
                finalized_migration_file: info[:finalized_migration_file],
                finalized_migration_milestone: milestone,
                next_required_stop: "unknown",
                current_gitlab_version: current_gitlab_version[:output],
                comment: "Error processing milestone: #{e.message}"
              }
            end
          end
        end

        unremovable_migrations
      end

      def execute_git_command(*args)
        git_args = ['git'] + args
        stdout, stderr, status = Open3.capture3(*git_args)
        if status.success?
          { success: true, output: stdout, error: stderr }
        else
          { success: false, output: nil, error: stderr }
        end
      end

      def target_branch
        ENV['CI_MERGE_REQUEST_TARGET_BRANCH_NAME'] || ENV['CI_DEFAULT_BRANCH'] || 'master'
      end

      # Format and display error messages
      def display_unremovable_migrations(unremovable_migrations)
        return if unremovable_migrations.empty?

        failure_messages = unremovable_migrations.map { |migration| format_migration_message(migration) }
        error_message = format(ERROR_MESSAGE, DOCUMENTATION, failure_messages.join("\n\n"))
        fail(error_message)
      end

      # Helper method to format a migration message
      def format_migration_message(migration)
        message = "**#{migration[:batched_background_migration_file]}**: #{migration[:comment]}"

        if migration[:finalized_migration_file]
          additional_info = []
          additional_info << "Finalized migration: #{migration[:finalized_migration_file]}"
          additional_info << "Finalized migration milestone: #{migration[:finalized_migration_milestone]}"

          if migration[:current_gitlab_version]
            additional_info << "Current GitLab version: #{migration[:current_gitlab_version]}"
          end

          additional_info << "Next required stop: #{migration[:next_required_stop]}" if migration[:next_required_stop]

          message += "\n #{additional_info.join("\n ")}" unless additional_info.empty?
        end

        message
      end
    end
  end
end
