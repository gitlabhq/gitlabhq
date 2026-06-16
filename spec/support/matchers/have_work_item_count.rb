# frozen_string_literal: true

require_relative '../helpers/capybara_node_helpers'

RSpec::Matchers.define :have_work_item_count do |count|
  include CapybaraNodeHelpers

  match do |actual|
    capybara_node_from(actual).has_selector?('[data-testid="issuable-container"]', count: count)
  end

  match_when_negated do |actual|
    capybara_node_from(actual).has_no_selector?('[data-testid="issuable-container"]', count: count)
  end

  failure_message do |actual|
    found = capybara_node_from(actual).all('[data-testid="issuable-container"]').count
    "expected to find #{count} work item(s), but found #{found}"
  end
end
