# frozen_string_literal: true

require_relative '../helpers/capybara_node_helpers'

# Verifies that rendered output contains a dismissible callout produced by
# one of the Users::Dismissible* components, without requiring specs to
# know the component's internal CSS classes or data attributes.
#
# The dismiss endpoint is derived from the resource argument:
# - no resource   => Users::Callout        (callouts_path)
# - group:        => Users::GroupCallout   (group_callouts_path)
# - project:      => Users::ProjectCallout (project_callouts_path)
#
# Examples:
#
#   expect(page).to have_dismissible_callout(feature_id: 'some_feature')
#   expect(page).to have_dismissible_callout(feature_id: 'some_feature', group: group)
#   expect(page).to have_dismissible_callout(feature_id: 'some_feature', project: project, defer_links: true)
RSpec::Matchers.define :have_dismissible_callout do |feature_id:, group: nil, project: nil, defer_links: nil|
  include CapybaraNodeHelpers

  def callout_selector(feature_id, group, project, defer_links)
    raise ArgumentError, 'pass only one of `group:` or `project:`' if group && project

    routing = ::Gitlab::Routing.url_helpers

    selector = ".js-persistent-callout[data-feature-id='#{feature_id}']"
    selector += if group
                  "[data-dismiss-endpoint='#{routing.group_callouts_path}'][data-group-id='#{group.id}']"
                elsif project
                  "[data-dismiss-endpoint='#{routing.project_callouts_path}'][data-project-id='#{project.id}']"
                else
                  "[data-dismiss-endpoint='#{routing.callouts_path}']"
                end

    # The component only emits data-defer-links='true' when defer_links is set;
    # the attribute is absent otherwise (it is never rendered as 'false').
    case defer_links
    when true
      selector += "[data-defer-links='true']"
    when false
      selector += ":not([data-defer-links])"
    end

    selector
  end

  match do |actual|
    selector = callout_selector(feature_id, group, project, defer_links)

    capybara_node_from(actual).has_css?(selector)
  end

  match_when_negated do |actual|
    selector = callout_selector(feature_id, group, project, defer_links)

    capybara_node_from(actual).has_no_css?(selector)
  end

  failure_message do
    "expected to find a dismissible callout matching '#{callout_selector(feature_id, group, project, defer_links)}'"
  end

  failure_message_when_negated do
    "expected not to find a dismissible callout matching " \
      "'#{callout_selector(feature_id, group, project, defer_links)}'"
  end
end
