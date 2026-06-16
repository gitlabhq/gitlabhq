# frozen_string_literal: true

module CapybaraNodeHelpers
  module_function

  # Returns a Capybara-queryable node for any value passed to a custom matcher.
  #
  # - For Capybara::Session, Capybara::Node::Base, Capybara::Node::Simple: returned as-is.
  # - For RSpec Rails rendered_content or any HTML string: wrapped via Capybara.string.
  #
  # Mirrors Capybara's own internal `wrap` method (in Capybara::RSpecMatchers::Matchers::Base),
  # which is private and therefore not reusable from outside.
  def capybara_node_from(actual)
    actual.respond_to?(:has_selector?) ? actual : Capybara.string(actual.to_s)
  end
end
