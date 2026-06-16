# frozen_string_literal: true

require_relative '../helpers/capybara_node_helpers'

RSpec::Matchers.define :have_issuable_counts do |opts|
  include CapybaraNodeHelpers

  expected_counts = opts.map do |state, count|
    "#{state.to_s.humanize} #{count}"
  end

  match do |actual|
    top_area = capybara_node_from(actual).find('.top-area')
    expected_counts.all? { |count| top_area.has_content?(count) }
  end

  match_when_negated do |actual|
    top_area = capybara_node_from(actual).find('.top-area')
    expected_counts.all? { |count| top_area.has_no_content?(count) }
  end

  description do
    "displays the following issuable counts: #{expected_counts.inspect}"
  end

  failure_message do
    "expected the following issuable counts: #{expected_counts.inspect} to be displayed"
  end
end
