# frozen_string_literal: true

RSpec::Matchers.define :be_one_of do |collection|
  match do |item|
    expect(collection).to include(item)
  end

  failure_message do |item|
    "expected #{item} to be one of #{collection}"
  end
end
