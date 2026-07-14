# frozen_string_literal: true

require_relative '../helpers/capybara_node_helpers'

# Basic matcher for view specs to do basic tracking data
# attribute verification.
RSpec::Matchers.define :have_tracking do |action:, label: nil, property: nil, testid: nil|
  include CapybaraNodeHelpers

  css = "[data-track-action='#{action}']"
  css += "[data-track-label='#{label}']" if label
  css += "[data-track-property='#{property}']" if property
  css += "[data-testid='#{testid}']" if testid

  match do |rendered|
    capybara_node_from(rendered).has_css?(css)
  end

  match_when_negated do |rendered|
    capybara_node_from(rendered).has_no_css?(css)
  end

  failure_message do
    "expected to find element matching CSS: #{css}"
  end

  failure_message_when_negated do
    "expected not to find element matching CSS: #{css}"
  end
end
