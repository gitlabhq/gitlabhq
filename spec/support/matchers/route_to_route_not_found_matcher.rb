# frozen_string_literal: true

RSpec::Matchers.define :route_to_route_not_found do
  match do |actual|
    expect(actual).to route_to(controller: 'application', action: 'route_not_found')
  rescue RSpec::Expectations::ExpectationNotMetError => e
    # `route_to` matcher requires providing all params for exact match. As we use it in shared examples and we provide different paths,
    # this matcher checks if provided route matches controller and action, without checking params.
    expect(e.message).to include("-{\"controller\"=>\"application\", \"action\"=>\"route_not_found\"}\n+{\"controller\"=>\"application\", \"action\"=>\"route_not_found\",")
  end

  failure_message do |_|
    "expected #{actual} to route to route_not_found"
  end
end
