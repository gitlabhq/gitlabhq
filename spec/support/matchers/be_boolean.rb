# frozen_string_literal: true

# Assert that this value is a boolean, i.e. true or false
#
# ```
# expect(value).to be_boolean
# ```
RSpec::Matchers.define :be_boolean do
  match { |value| value.in? [true, false] }
end
