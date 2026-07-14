# frozen_string_literal: true

require_relative '../helpers/capybara_node_helpers'

RSpec::Matchers.define :have_emoji do |emoji_name|
  include CapybaraNodeHelpers

  match do |actual|
    capybara_node_from(actual).has_selector?("gl-emoji[data-name='#{emoji_name}']")
  end

  match_when_negated do |actual|
    capybara_node_from(actual).has_no_selector?("gl-emoji[data-name='#{emoji_name}']")
  end

  failure_message do
    "expected to find <gl-emoji data-name='#{emoji_name}'>"
  end

  failure_message_when_negated do
    "expected not to find <gl-emoji data-name='#{emoji_name}'>"
  end
end
