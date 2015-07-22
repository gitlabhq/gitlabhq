# Extend shoulda-matchers
module Shoulda::Matchers::ActiveModel
  class ValidateLengthOfMatcher
    # Shortcut for is_at_least and is_at_most
    def is_within(range)
      is_at_least(range.min) && is_at_most(range.max)
    end
  end
end
