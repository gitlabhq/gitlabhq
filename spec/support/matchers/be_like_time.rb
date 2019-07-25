# frozen_string_literal: true

RSpec::Matchers.define :be_like_time do |expected|
  match do |actual|
    expect(actual).to be_within(1.second).of(expected)
  end

  description do
    "within one second of #{expected}"
  end

  failure_message do |actual|
    "expected #{actual} to be within one second of #{expected}"
  end
end
