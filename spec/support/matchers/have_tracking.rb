# frozen_string_literal: true

# Basic matcher for view specs to do basic tracking data
# attribute verification.
RSpec::Matchers.define :have_tracking do |action:, label: nil, property: nil, testid: nil|
  match do |rendered|
    css = "[data-track-action='#{action}']"
    css += "[data-track-label='#{label}']" if label
    css += "[data-track-property='#{property}']" if property
    css += "[data-testid='#{testid}']" if testid

    expect(rendered).to have_css(css)
  end
end
