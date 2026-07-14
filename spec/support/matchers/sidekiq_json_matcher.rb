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

    failure_message do |hash_array|
      bad_index = hash_array.index do |hash|
        !(all_keys_are_strings(hash) && all_values_are_valid_json_types?(hash))
      end
      hash = hash_array[bad_index]
      non_string_keys = hash.keys.reject { |k| k.is_a?(String) }
      invalid_values = hash.reject { |_k, v| NATIVE_JSON_TYPES.include?(v.class) }
      msg = "expected hash at index #{bad_index} to contain only string keys and native JSON values"
      msg += "\n  non-string keys: #{non_string_keys.inspect}" if non_string_keys.any?
      msg += "\n  invalid value types: #{invalid_values.transform_values(&:class).inspect}" if invalid_values.any?
      msg
    end
  end
end
