# frozen_string_literal: true

# Assert the result matches a URI object initialized with the expectation variable.
#
# Success:
# ```
# expect(URI('www.fish.com')).to eq_uri('www.fish.com')
# ```
#
# Failure:
# ```
# expect(URI('www.fish.com')).to eq_uri('www.dog.com')
# ```
#
RSpec::Matchers.define :eq_uri do |expected|
  match do |actual|
    actual == URI(expected)
  end
end
