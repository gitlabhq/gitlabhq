# frozen_string_literal: true

module ExceedRedisCallLimitHelpers
  def build_recorder(block)
    return block if block.is_a?(RedisCommands::Recorder)

    RedisCommands::Recorder.new(&block)
  end

  def verify_count(expected, block)
    @actual = build_recorder(block).count

    @actual > expected
  end

  def verify_commands_count(command, expected, block)
    @actual = build_recorder(block).by_command(command.to_s).count

    @actual > expected
  end
end

RSpec::Matchers.define :exceed_redis_calls_limit do |expected|
  supports_block_expectations

  include ExceedRedisCallLimitHelpers

  match do |block|
    verify_count(expected, block)
  end

  failure_message do
    "Expected at least #{expected} calls, but got #{actual}"
  end

  failure_message_when_negated do
    "Expected a maximum of #{expected} calls, but got #{actual}"
  end
end

RSpec::Matchers.define :exceed_redis_command_calls_limit do |command, expected|
  supports_block_expectations

  include ExceedRedisCallLimitHelpers

  match do |block|
    verify_commands_count(command, expected, block)
  end

  failure_message do
    "Expected at least #{expected} calls to '#{command}', but got #{actual}"
  end

  failure_message_when_negated do
    "Expected a maximum of #{expected} calls to '#{command}', but got #{actual}"
  end
end
