# frozen_string_literal: true

# Matcher to check that an object raises NoMethodError when a method is called
RSpec::Matchers.define :require_method_definition do |method_name, *args|
  attr_accessor :arguments

  match do |obj|
    expect { obj.send(method_name, *args) }.to raise_error(NoMethodError)
  end

  failure_message do |obj|
    "expected #{obj} to raise NoMethodError when calling :#{method_name}, but nothing was raised."
  end

  failure_message_when_negated do |obj|
    "expected #{obj} not to raise NoMethodError when calling :#{method_name}, but it did."
  end
end
