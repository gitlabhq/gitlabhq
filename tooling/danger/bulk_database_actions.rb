# frozen_string_literal: true

require_relative 'suggestion'

module Tooling
  module Danger
    class BulkDatabaseActions < Suggestion
      MATCH = %r{\A\+\s+(\S*\.)?((bulk_)?(insert|update|upsert|delete|destroy)(_all)?)\b}
      REPLACEMENT = nil
      DOCUMENTATION_LINK = 'https://docs.gitlab.com/ee/development/database_review.html#preparation-when-using-bulk-update-operations'

      SUGGESTION = <<~MESSAGE_MARKDOWN.freeze
        When using `insert`, `update`, `upsert`, `delete`, `destroy` commands, or their `bulk/all` variants (e.g., `bulk_insert`, `update_all`), you must include the full
        database query and query execution plan in the merge request
        description, and request a ~database review.

        This comment can be ignored if the object is not an ActiveRecord class,
        since no database query would be generated.

        ----

        For more information, see [Database Review documentation](#{DOCUMENTATION_LINK}).
      MESSAGE_MARKDOWN
    end
  end
end
