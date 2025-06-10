# frozen_string_literal: true

module Tooling
  module Danger
    module FinalizeBatchedBackgroundMigrationValidatorHelper
      POST_MIGRATE_PATH = [
        'db/post_migrate',
        'ee/db/geo/post_migrate',
        'ee/db/embedding/post_migrate'
      ].freeze

      def validate_migrations(changed_files)
        post_migrate_migrations = changed_files.select { |f| f.match?(%r{^(?:#{POST_MIGRATE_PATH.join('|')})/.+$}) }

        return if post_migrate_migrations.empty?

        errors = []

        post_migrate_migrations.each do |file_path|
          file_content = File.read(file_path)

          # Check only finalize batched background migration files
          next unless file_content.include?('ensure_batched_background_migration_is_finished')

          errors << validate_job_class_name_format(file_path, file_content)

          errors << validate_migration_count(file_path, file_content)
        end
        display_errors(errors.compact)
      end

      def validate_job_class_name_format(file_path, file_content)
        return unless file_content.include?('job_class_name')

        return if file_content.match?(/job_class_name:[ \t]*["'][A-Za-z0-9]+["']/)

        { file: file_path,
          message: "The value of job_class_name should be a string in PascalCase e.g 'FinalizeMigrationClass' " }
      end

      def validate_migration_count(file_path, file_content)
        occurrences = file_content.scan(/ensure_batched_background_migration_is_finished/).count
        return unless occurrences != 1

        { file: file_path, message: "There should only be one finalize batched background migration per class" }
      end

      def display_errors(errors)
        return if errors.empty?

        failure_messages = errors.map do |error|
          "**#{error[:file]}**: #{error[:message]}"
        end

        return unless failure_messages.any?

        fail(failure_messages)
      end
    end
  end
end
