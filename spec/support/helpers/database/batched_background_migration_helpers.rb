# frozen_string_literal: true

module Database
  module BatchedBackgroundMigrationHelpers
    def migrate_down_on_each_database_if_finalized!
      return unless finalized?

      Gitlab::Database.database_base_models_with_gitlab_shared.each_value do |config_model|
        if config_model == ActiveRecord::Base
          migrate_down_to_finalized_version!
          next
        end

        with_reestablished_active_record_base do
          reconfigure_db_connection(
            model: ActiveRecord::Base,
            config_model: config_model
          )

          migrate_down_to_finalized_version!
        end
      end
    end

    def background_migration?
      self.class.metadata[:level] == :background_migration
    end

    def migrate_down_to_finalized_version!
      disable_migrations_output do
        migration_context.down(finalized_by_version)
      end
    end

    def finalized?
      migration_dictionary_entry&.finalized_by.present?
    end

    def finalized_by_version
      migration_dictionary_entry.finalized_by.to_i
    end

    def migration_dictionary_entry
      @migration_dictionary_entry ||= ::Gitlab::Utils::BatchedBackgroundMigrationsDictionary
        .entry(described_class.to_s.demodulize)
    end
  end
end
