# frozen_string_literal: true

require_relative 'capybara_node_helpers'

module TestidHelpers
  include CapybaraNodeHelpers

  def has_testid?(testid, context: page, **kwargs)
    capybara_node_from(context).has_selector?("[data-testid='#{testid}']", **kwargs)
  end

  def find_by_testid(testid, context: page, **kwargs)
    capybara_node_from(context).find("[data-testid='#{testid}']", **kwargs)
  end

  def all_by_testid(testid, context: page, **kwargs)
    capybara_node_from(context).all("[data-testid='#{testid}']", **kwargs)
  end

  # `within` is a Capybara::Session-only operation - Capybara::Node::Simple
  # does not support it, so this helper can't be wrapped for view-spec use.
  def within_testid(testid, context: page, **kwargs, &block)
    context.within("[data-testid='#{testid}']", **kwargs, &block)
  end

  RSpec::Matchers.define :have_no_testid do |testid, **kwargs|
    include CapybaraNodeHelpers

    match do |context|
      capybara_node_from(context).has_no_css?("[data-testid='#{testid}']", **kwargs)
    end

    failure_message do
      "expected not to find element with data-testid='#{testid}'"
    end
  end
end
