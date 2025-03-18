# frozen_string_literal: true

# Sidekiq expects params to workers as valid, simple JSON.
# Hashes should have string keys and values of native JSON types.
# See https://github.com/sidekiq/sidekiq/wiki/Best-Practices
# This matcher tests if an array of hashes has all string keys
# and if all values upto one level of nesting, are of native JSON types.

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
    (hash.values.map(&:class).uniq - NATIVE_JSON_TYPES).empty?
  end

  def all_keys_are_strings(hash)
    hash.keys.all?(String)
  end

  RSpec::Matchers.define :param_containing_valid_native_json_types do
    match do |hash_array|
      hash_array.all? { |hash| all_keys_are_strings(hash) && all_values_are_valid_json_types?(hash) }
    end
  end
end
