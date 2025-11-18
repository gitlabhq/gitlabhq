# frozen_string_literal: true

RSpec::Matchers.define :have_testid do |testid, text: nil|
  match do |actual|
    expect(actual).to have_selector("[data-testid='#{testid}']", text: text)
  end
end
