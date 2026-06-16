# frozen_string_literal: true

require_relative '../helpers/capybara_node_helpers'

# These matchers look for selectors within the Vue navigation sidebar.
# They should therefore be used in feature specs with the Js driver enabled.

RSpec::Matchers.define :have_active_navigation do |expected|
  include CapybaraNodeHelpers

  match do |page|
    sidebar = capybara_node_from(page).find('[data-testid="super-sidebar"]')
    sidebar.has_selector?('button[aria-expanded="true"]', text: expected)
  end

  match_when_negated do |page|
    sidebar = capybara_node_from(page).find('[data-testid="super-sidebar"]')
    sidebar.has_no_selector?('button[aria-expanded="true"]', text: expected)
  end
end

RSpec::Matchers.define :have_active_sub_navigation do |expected|
  include CapybaraNodeHelpers

  match do |page|
    sidebar = capybara_node_from(page).find('[data-testid="super-sidebar"]')
    sidebar.has_selector?('[aria-current="page"]', text: expected)
  end

  match_when_negated do |page|
    sidebar = capybara_node_from(page).find('[data-testid="super-sidebar"]')
    sidebar.has_no_selector?('[aria-current="page"]', text: expected)
  end
end
