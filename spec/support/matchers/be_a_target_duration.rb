# frozen_string_literal: true

RSpec::Matchers.define :be_a_target_duration do |expected|
  match do |actual|
    actual.is_a?(::Gitlab::EndpointAttributes::Config::Duration) && actual.name == expected
  end
end
