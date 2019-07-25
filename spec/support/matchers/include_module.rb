# frozen_string_literal: true

RSpec::Matchers.define :include_module do |expected|
  match do
    described_class.included_modules.include?(expected)
  end

  description do
    "includes the #{expected} module"
  end

  failure_message do
    "expected #{described_class} to include the #{expected} module"
  end
end
