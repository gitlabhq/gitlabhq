# frozen_string_literal: true

# Helper to process deletions of associated records created via loose foreign keys

module LooseForeignKeysHelper
  class SpecModificationTracker < LooseForeignKeys::ModificationTracker
    # Redefine over_limit? to not have time limit as this has been found
    # to be too slow and flaky in the inconsistent CI performance.
    # Context: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/187891#note_2448115940
    def over_limit?
      @delete_count_by_table.values.sum >= max_deletes ||
        @update_count_by_table.values.sum >= max_updates
    end
  end

  def process_loose_foreign_key_deletions(record:, worker_class: nil)
    service_params = {
      connection: record.connection,
      modification_tracker: SpecModificationTracker.new,
      record_store: Gitlab::LooseForeignKeys::DeletedRecordStore
    }

    service_params[:worker_class] = worker_class if worker_class

    LooseForeignKeys::ProcessDeletedRecordsService.new(**service_params).execute
  end

  # Cleans up the children of the given loose foreign keys only, so examples that
  # test one definition skip the other children of busy parents such as projects.
  def process_loose_foreign_key_definitions(definitions:, record:)
    connection = record.connection
    parent_table = LooseForeignKeysHelper.parent_table_for(definitions)

    LooseForeignKeys::BatchCleanerService.new(
      parent_table: parent_table,
      loose_foreign_key_definitions: definitions,
      deleted_parent_records: LooseForeignKeysHelper.deleted_records_for(connection, parent_table),
      connection: connection,
      modification_tracker: SpecModificationTracker.new,
      record_store: Gitlab::LooseForeignKeys::DeletedRecordStore
    ).execute
  end

  def self.parent_table_for(definitions)
    if definitions.blank?
      raise ArgumentError, "Expected at least one loose foreign key definition, got #{definitions.inspect}"
    end

    definitions.first.to_table
  end

  def self.deleted_records_for(connection, parent_table)
    Gitlab::Database::SharedModel.using_connection(connection) do
      Gitlab::LooseForeignKeys::DeletedRecordStore.load_batch_for_table(
        "#{connection.current_schema}.#{parent_table}",
        LooseForeignKeys::ProcessDeletedRecordsService::BATCH_SIZE
      )
    end
  end
end
