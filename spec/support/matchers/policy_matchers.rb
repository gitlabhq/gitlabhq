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

RSpec::Matchers.define :delegate_to do |expected|
  match do |actual|
    actual.delegated_policies.values.any?(expected)
  end

  failure_message do |actual|
    "expected #{actual.class.name} to delegate to #{expected.name}, but it does not"
  end

  failure_message_when_negated do |actual|
    "expected #{actual.class.name} not to delegate to #{expected.name}, but it does"
  end
end
