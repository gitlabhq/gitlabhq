# frozen_string_literal: true

# These matchers are a syntactic hack to provide more readable expectations for
# an Enumerable object.
#
# They take advantage of the `all?`, `none?`, and `one?` methods, and the fact
# that RSpec provides a `be_something` matcher for all predicates.
#
# Example:
#
#   # Ensure exactly one object in an Array satisfies a condition
#   expect(users.one? { |u| u.admin? }).to eq true
#
#   # The same thing, but using the `be_one` matcher
#   expect(users).to be_one { |u| u.admin? }
#
#   # The same thing again, but using `satisfy_one` for improved readability
#   expect(users).to satisfy_one { |u| u.admin? }
RSpec::Matchers.alias_matcher :satisfy_all,  :be_all
RSpec::Matchers.alias_matcher :satisfy_none, :be_none
RSpec::Matchers.alias_matcher :satisfy_one,  :be_one
