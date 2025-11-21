# frozen_string_literal: true

RSpec::Matchers.define :include_module do |expected|
  def target(actual)
    actual.is_a?(Module) ? actual : actual.class
  end

  match do |actual|
    target(actual).included_modules.include?(expected)
  end

  description do
    "includes the #{expected} module"
  end

  failure_message do |actual|
    "expected #{target(actual)} to include the #{expected} module"
  end
end
