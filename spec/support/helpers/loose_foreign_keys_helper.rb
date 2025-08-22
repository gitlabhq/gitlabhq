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
      modification_tracker: SpecModificationTracker.new
    }

    service_params[:worker_class] = worker_class if worker_class

    LooseForeignKeys::ProcessDeletedRecordsService.new(**service_params).execute
  end
end
