# frozen_string_literal: true

require_relative 'suggestion'

module Tooling
  module Danger
    class IndexRemoval < Suggestion
      INDEX_REMOVAL_METHODS = 'remove_concurrent_index_by_name|remove_concurrent_index|remove_index'
      DROP_INDEX_SQL = 'DROP\s+INDEX(\s+CONCURRENTLY)?(\s+IF\s+EXISTS)?'

      MATCH = %r{\A\+(?!\s*#).*?(#{INDEX_REMOVAL_METHODS}|#{DROP_INDEX_SQL})}i
      REPLACEMENT = nil
      ONCE_PER_FILE = true

      DOCUMENTATION_LINK = 'https://docs.gitlab.com/development/database/adding_database_indexes/#investigating-index-usage'
      DUPLICATE_INDEXES_PATH = 'spec/support/helpers/database/duplicate_indexes.yml'

      SUGGESTION = <<~MESSAGE_MARKDOWN.freeze
        ⚠️ **Index Removal Detected**

        This migration removes a database index. Before merging, please verify:

        1. **Check index usage** via `pg_stat_user_indexes` to confirm the index is unused
        2. **Review the query patterns** that may rely on this index
        3. **Consider if this is a redundant index** (covered by another index)

        If this index is listed in [`duplicate_indexes.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/#{DUPLICATE_INDEXES_PATH}),
        it's already identified as redundant and safe to remove.

        For more information, see: [Investigating index usage](#{DOCUMENTATION_LINK})
      MESSAGE_MARKDOWN
    end
  end
end
