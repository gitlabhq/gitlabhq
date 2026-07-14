# frozen_string_literal: true

require_relative '../helpers/capybara_node_helpers'

RSpec::Matchers.define :have_testid do |testid, **options|
  include CapybaraNodeHelpers

  match do |actual|
    capybara_node_from(actual).has_selector?("[data-testid='#{testid}']", **options)
  end

  match_when_negated do |actual|
    capybara_node_from(actual).has_no_selector?("[data-testid='#{testid}']", **options)
  end

  failure_message do
    msg = "expected to find element with data-testid='#{testid}'"
    msg += " containing text '#{text}'" if text
    msg
  end

  failure_message_when_negated do
    msg = "expected not to find element with data-testid='#{testid}'"
    msg += " containing text '#{text}'" if text
    msg
  end
end
