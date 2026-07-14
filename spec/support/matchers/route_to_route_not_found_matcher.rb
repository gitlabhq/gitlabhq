# frozen_string_literal: true

RSpec::Matchers.define :route_to_route_not_found do
  match do |actual|
    # The `route_to` matcher requires providing all params for an exact match.
    # As we use this in shared examples with different paths, we recognize the
    # path ourselves and only assert on the controller and action, ignoring the
    # remaining params (such as the wildcard `unmatched_route`).
    method, path = actual.first
    params = Rails.application.routes.recognize_path(path, method: method)

    params[:controller] == 'application' && params[:action] == 'route_not_found'
  rescue ActionController::RoutingError
    false
  end

  failure_message do |_|
    "expected #{actual} to route to route_not_found"
  end
end
