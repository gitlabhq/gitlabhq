# frozen_string_literal: true

RSpec.configure do |config|
  config.include SnowplowHelpers, :snowplow

  config.before(:each, :snowplow) do
    # Using a high buffer size to not cause early flushes
    buffer_size = 100
    # WebMock is set up to allow requests to `localhost`
    host = 'localhost'

    allow_any_instance_of(Gitlab::Tracking::Destinations::ProductAnalytics).to receive(:event)

    allow_any_instance_of(Gitlab::Tracking::Destinations::Snowplow)
      .to receive(:emitter)
      .and_return(SnowplowTracker::Emitter.new(host, buffer_size: buffer_size))

    stub_application_setting(snowplow_enabled: true)

    allow(Gitlab::Tracking).to receive(:event).and_call_original # rubocop:disable RSpec/ExpectGitlabTracking
  end

  config.after(:each, :snowplow) do
    Gitlab::Tracking.send(:snowplow).send(:tracker).flush
  end
end
