# frozen_string_literal: true

SystemExitDetected = Class.new(RuntimeError)

RSpec.configure do |config|
  config.around do |example|
    example.run
  rescue SystemExit
    # In any cases, we cannot raise SystemExit in the tests,
    # because it'll skip any following tests from running.
    # Convert it to something that won't skip everything.
    # See https://gitlab.com/gitlab-org/gitlab/-/issues/350060

    raise if ENV['RSPEC_BYPASS_SYSTEM_EXIT_PROTECTION'] == 'true'

    raise SystemExitDetected, "SystemExit should be rescued in the tests!"
  end
end
