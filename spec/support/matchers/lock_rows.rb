# frozen_string_literal: true

# This matcher can assert that rows have been locked with a specific lock type.
# You will need to add the lock_recorder metadata for the matcher to operate properly.
#
# Usage:
#
# RSpec.describe SomeCLass do
#   context 'some_method', :lock_recorder' do
#     it do
#       expect { some_method_with_locking }.to lock_rows(some_object => 'FOR UPDATE')
#     end
#   end
# end
#
# There are more examples within spec/support_specs/matchers/lock_rows_spec.rb
#
RSpec::Matchers.define :lock_rows do |expected_locks|
  supports_block_expectations

  match do |action|
    track_locks(&action)
    expected_locks = normalize_expected_locks(expected_locks)
    locks_match?(expected_locks)
  end

  failure_message do
    build_failure_message(expected_locks)
  end

  failure_message_when_negated do
    "Expected NOT to lock rows with #{expected_locks}, but locked #{@actual_locks}"
  end

  private

  def lock_recorder
    Gitlab::Database::LockRecorder.instance
  end

  def track_locks
    lock_recorder.start
    yield
    lock_recorder.stop
  end

  def normalize_expected_locks(expected_locks)
    expected_locks.transform_keys do |key|
      Gitlab::Database::LockRecorder.record_key(key)
    end
  end

  def locks_match?(expected_locks)
    @unmatched_locks = find_unmatched_locks(expected_locks)
    @extra_locks = find_extra_locks(expected_locks)

    @unmatched_locks.empty? && @extra_locks.empty?
  end

  def find_unmatched_locks(expected_locks)
    expected_locks.reject { |key, mode| lock_recorder.locks[key] == mode }
  end

  def find_extra_locks(expected_locks)
    lock_recorder.locks.reject { |key, _| expected_locks.key?(key) }
  end

  def build_failure_message(expected_locks)
    MessageBuilder.new(
      expected_locks: expected_locks,
      actual_locks: lock_recorder.locks,
      extra_locks: @extra_locks,
      unmatched_locks: @unmatched_locks
    ).build
  end

  # rubocop:disable Lint/ConstantDefinitionInBlock -- self contained matcher
  # rubocop:disable Gitlab/NamespacedClass -- it's just a matcher convenience class
  class MessageBuilder
    def initialize(expected_locks:, actual_locks:, extra_locks:, unmatched_locks:)
      @expected_locks = expected_locks
      @actual_locks = actual_locks
      @extra_locks = extra_locks
      @unmatched_locks = unmatched_locks
    end

    def build
      [
        base_message,
        extra_locks_message,
        missing_locks_message,
        wrong_locks_message
      ].compact.join("\n")
    end

    private

    def lock_recorder
      Gitlab::Database::LockRecorder.instance
    end

    def base_message
      "Expected locks:\n#{format_locks(@expected_locks)},\nbut got:\n#{format_locks(@actual_locks)}."
    end

    def extra_locks_message
      return if @extra_locks.empty?

      "Extra locks detected (not expected): #{format_locks(@extra_locks)}"
    end

    def missing_locks_message
      missing = @expected_locks.keys - @actual_locks.keys
      return if missing.empty?

      "Missing locks (expected but not locked): #{format_keys(missing)}"
    end

    def wrong_locks_message
      wrong_locks = find_wrong_locks
      return if wrong_locks.empty?

      build_wrong_locks_message(wrong_locks)
    end

    def find_wrong_locks
      @expected_locks.select do |key, mode|
        lock_recorder.locks[key] && lock_recorder.locks[key] != mode
      end
    end

    def build_wrong_locks_message(wrong_locks)
      message = ["Records locked with the wrong mode:"]
      wrong_locks.each do |key, expected_mode|
        message << "  - #{format_key(key)} expected: #{expected_mode}, got: #{lock_recorder.locks[key]}"
      end
      message.join("\n")
    end

    def format_locks(locks)
      locks.map { |key, mode| "#{format_key(key)} => #{mode}" }.join(", ")
    end

    def format_keys(keys)
      keys.map { |key| format_key(key) }.join(", ")
    end

    def format_key(key)
      table_name, id = key
      "#{table_name}(#{id})"
    end
  end
  # rubocop:enable Lint/ConstantDefinitionInBlock
  # rubocop:enable Gitlab/NamespacedClass
end

RSpec::Matchers.alias_matcher :lock_row, :lock_rows
