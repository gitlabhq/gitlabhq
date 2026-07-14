# frozen_string_literal: true

# Assert all the given id columns are one of the foreign key columns:
#
# ```
# id_columns = ['partition_id']
# composite_keys = [['partition_id', 'build_id', 'name']]
# expect(id_columns).to be_a_foreign_key_column_of(composite_keys)
# ```
#
RSpec::Matchers.define :be_a_foreign_key_column_of do |composite_keys|
  match do |id_columns|
    id_columns.all? do |id_column|
      composite_keys.any? do |composite_key|
        composite_key.include?(id_column)
      end
    end
  end

  failure_message do |id_columns|
    missing = id_columns.reject do |id_column|
      composite_keys.any? { |composite_key| composite_key.include?(id_column) }
    end
    "expected all of #{id_columns.inspect} to be foreign key columns in #{composite_keys.inspect}, " \
      "but these are not: #{missing.inspect}"
  end
end
