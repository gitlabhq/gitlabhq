# frozen_string_literal: true

RSpec::Matchers.define :allow_action do |action|
  match do |policy|
    expect(policy).to be_allowed(action)
  end

  failure_message do |policy|
    policy.debug(action, debug_output = +'')
    "expected #{policy} to allow #{action}\n\n#{debug_output}"
  end

  failure_message_when_negated do |policy|
    policy.debug(action, debug_output = +'')
    "expected #{policy} not to allow #{action}\n\n#{debug_output}"
  end
end
