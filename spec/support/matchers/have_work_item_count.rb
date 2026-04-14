# frozen_string_literal: true

RSpec::Matchers.define :have_work_item_count do |count|
  match do |actual|
    actual.has_selector?('[data-testid="issuable-container"]', count: count)
  end

  failure_message do |actual|
    "expected to find #{count} work item(s), but found #{actual.all('[data-testid="issuable-container"]').count}"
  end
end
