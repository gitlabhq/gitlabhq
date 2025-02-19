# frozen_string_literal: true

# Sidekiq expects params to workers as valid, simple JSON.
# Hashes should have string keys and values of native JSON types.
# See https://github.com/sidekiq/sidekiq/wiki/Best-Practices
# Here, we want to test that the params generated in `bulk_create_delete_events_async`
# are as Sidekiq would expect them to be.

module SidekiqJSONMatcher
  NATIVE_JSON_TYPES = [
    String,
    Integer,
    Float,
    TrueClass,
    FalseClass,
    NilClass,
    Array,
    Hash
  ].freeze

  def all_values_are_valid_json_types?(hash)
    (NATIVE_JSON_TYPES - hash.values.map(&:class).uniq!).empty?
  end

  def all_keys_are_strings(hash)
    (hash.keys.map(&:class).uniq! == [String])
  end

  RSpec::Matchers.define :param_containing_valid_native_json_types do
    match do |hash_array|
      hash_array.each { |hash| all_keys_are_strings(hash) && all_values_are_valid_json_types?(hash) }
    end
  end
end
