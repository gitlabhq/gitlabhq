# frozen_string_literal: true

RSpec::Matchers.define :have_testid do |testid|
  match do |actual|
    expect(actual).to have_selector("[data-testid='#{testid}']")
  end
end
