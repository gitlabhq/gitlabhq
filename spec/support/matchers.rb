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

# Extend shoulda-matchers
module Shoulda::Matchers::ActiveModel
  class ValidateLengthOfMatcher
    # Shortcut for is_at_least and is_at_most
    def is_within(range)
      is_at_least(range.min) && is_at_most(range.max)
    end
  end
end
