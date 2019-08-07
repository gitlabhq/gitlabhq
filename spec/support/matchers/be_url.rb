# frozen_string_literal: true

RSpec::Matchers.define :be_url do |_|
  match do |actual|
    URI.parse(actual) rescue false
  end
end

# looks better when used like:
#   expect(thing).to receive(:method).with(a_valid_url)
RSpec::Matchers.alias_matcher :a_valid_url, :be_url
