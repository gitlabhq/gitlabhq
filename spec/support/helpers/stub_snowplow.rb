# frozen_string_literal: true

module StubSnowplow
  def stub_snowplow
    # Using a high buffer size to not cause early flushes
    buffer_size = 100
    # WebMock is set up to allow requests to `localhost`
    host = 'localhost'

    # rubocop:disable RSpec/AnyInstanceOf
    allow_any_instance_of(Gitlab::Tracking::Destinations::Snowplow)
      .to receive(:emitter)
            .and_return(SnowplowTracker::Emitter.new(endpoint: host, options: { buffer_size: buffer_size }))
    # rubocop:enable RSpec/AnyInstanceOf

    stub_application_setting(snowplow_enabled: true, snowplow_collector_hostname: host)

    allow(SnowplowTracker::SelfDescribingJson).to receive(:new).and_call_original
    allow(Gitlab::Tracking).to receive(:event).and_call_original # rubocop:disable RSpec/ExpectGitlabTracking
  end
end
