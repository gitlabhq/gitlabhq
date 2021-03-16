# frozen_string_literal: true

require_relative 'stub_snowplow'

RSpec.configure do |config|
  config.include SnowplowHelpers, :snowplow
  config.include StubSnowplow, :snowplow

  config.before(:each, :snowplow) do
    stub_snowplow
  end

  config.after(:each, :snowplow) do
    Gitlab::Tracking.send(:snowplow).send(:tracker).flush
  end
end
