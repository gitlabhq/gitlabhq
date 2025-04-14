# frozen_string_literal: true

# Assert all the given foreign keys are indexed:
#
# ```
# composite_foreign_keys = [['build_id', 'partition_id']]
# indexed_columns = [['build_id', 'name', 'partition_id'], ['partition_id', 'build_id', 'name']]
# expect(composite_foreign_keys).to be_indexed_by(indexed_columns)
# ```
#
RSpec::Matchers.define :be_indexed_by do |indexed_columns|
  match do |foreign_key|
    indexed_columns.any? do |index|
      foreign_key_columns = Array.wrap(foreign_key.column) # Sometimes it is composite and already an array

      # for example, [build_id, partition_id] should be covered by indexes e.g.
      # - [build_id, partition_id, name]
      # - [partition_id, build_id, name]
      # but not by [build_id, name, partition_id]
      # therefore, we just need to take the first few columns (same length as composite key)
      # e.g. [partition_id, build_id] of [partition_id, build_id, name]
      # and compare with [build_id, partition_id]
      (foreign_key_columns - index.first(foreign_key_columns.length)).blank?
    end
  end
  failure_message do |foreign_key|
    <<~MESSAGE
    Missing a required index for:

      table: #{foreign_key.from_table.split('.').last}
      column: (#{Array.wrap(foreign_key.column).join(',')})

    All foreign keys must have indexes per
    https://docs.gitlab.com/development/database/foreign_keys/#indexes
    MESSAGE
  end
end
