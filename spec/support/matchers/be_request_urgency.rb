# frozen_string_literal: true

RSpec::Matchers.define :be_request_urgency do |expected|
  match do |actual|
    actual.is_a?(::Gitlab::EndpointAttributes::Config::RequestUrgency) &&
      actual.name == expected
  end
end
