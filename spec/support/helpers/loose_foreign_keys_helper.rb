# frozen_string_literal: true

# Helper to process deletions of associated records created via loose foreign keys

module LooseForeignKeysHelper
  def process_loose_foreign_key_deletions(record:)
    LooseForeignKeys::DeletedRecord.using_connection(record.connection) do
      LooseForeignKeys::ProcessDeletedRecordsService.new(connection: record.connection).execute
    end
  end
end
