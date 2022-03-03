# frozen_string_literal: true

# Assert that this value is a valid color equal to the argument
#
# ```
# expect(value).to be_color('#fff')
# ```
RSpec::Matchers.define :be_color do |expected|
  match do |actual|
    next false unless actual.present?

    if expected
      ::Gitlab::Color.of(actual) == ::Gitlab::Color.of(expected)
    else
      ::Gitlab::Color.of(actual).valid?
    end
  end
end

RSpec::Matchers.alias_matcher :a_valid_color, :be_color
