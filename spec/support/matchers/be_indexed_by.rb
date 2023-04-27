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
  match do |composite_foreign_keys|
    composite_foreign_keys.all? do |composite_foreign_key|
      indexed_columns.any? do |columns|
        # for example, [build_id, partition_id] should be covered by indexes e.g.
        # - [build_id, partition_id, name]
        # - [partition_id, build_id, name]
        # but not by [build_id, name, partition_id]
        # therefore, we just need to take the first few columns (same length as composite key)
        # e.g. [partition_id, build_id] of [partition_id, build_id, name]
        # and compare with [build_id, partition_id]
        (composite_foreign_key - columns.first(composite_foreign_key.length)).blank?
      end
    end
  end
end
