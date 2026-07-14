# frozen_string_literal: true

require_relative '../helpers/capybara_node_helpers'

RSpec::Matchers.define :show_user_status do |status|
  include CapybaraNodeHelpers

  selector = ".user-status-emoji[title='#{status.message}'] " \
    "gl-emoji[data-name='#{status.emoji}']"

  match do |page|
    capybara_node_from(page).has_selector?(selector)
  end

  match_when_negated do |page|
    capybara_node_from(page).has_no_selector?(selector)
  end

  failure_message do
    "expected to find user status with message '#{status.message}' containing emoji '#{status.emoji}'"
  end

  failure_message_when_negated do
    "expected not to find user status with message '#{status.message}' containing emoji '#{status.emoji}'"
  end
end
