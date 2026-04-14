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

RSpec::Matchers.define :override_delegates_for do |*abilities|
  def format_abilities(set)
    set.empty? ? 'nothing' : set.map { |a| ":#{a}" }.join(', ')
  end

  match do |policy_class|
    @overrides = policy_class.overrides
    @missing = abilities.to_set - @overrides
    @missing.empty?
  end

  failure_message do |policy_class|
    expected = format_abilities(abilities)

    msg = "expected #{policy_class.name} to override #{expected}\n"
    msg << "  missing:  #{format_abilities(@missing)}\n"
    msg << "  actually overrides: #{format_abilities(@overrides)}"
  end

  failure_message_when_negated do |policy_class|
    expected = format_abilities(abilities)
    unexpected = abilities.to_set & @overrides

    msg = "expected #{policy_class.name} not to override #{expected}\n"
    msg << "  unexpectedly overrides: #{format_abilities(unexpected)}\n"
    msg << "  all overrides: #{format_abilities(@overrides)}"
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
