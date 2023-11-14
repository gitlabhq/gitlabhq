# frozen_string_literal: true

# These matches look for selectors within the Vue navigation sidebar.
# They should therefore be used in feature specs with the Js driver enabled.

RSpec::Matchers.define :have_active_navigation do |expected|
  match do |page|
    within_testid('super-sidebar') do
      expect(page).to have_selector('button[aria-expanded="true"]', text: expected)
    end
  end
end

RSpec::Matchers.define :have_active_sub_navigation do |expected|
  match do |page|
    within_testid('super-sidebar') do
      expect(page).to have_selector('[aria-current="page"]', text: expected)
    end
  end
end
