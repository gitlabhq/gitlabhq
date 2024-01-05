# frozen_string_literal: true

# TODO: Remove the debug_with_puts statements below! Used for debugging purposes.
# TODO: https://gitlab.com/gitlab-org/quality/engineering-productivity/team/-/issues/323#note_1688925316
module DebugWithPuts
  def debug_with_puts(message)
    return unless ENV['CI'] # rubocop:disable RSpec/AvoidConditionalStatements -- Debug information only in the CI

    warn "[#{Time.current}] #{message}"
  end

  module_function :debug_with_puts
end
