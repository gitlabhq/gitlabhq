# frozen_string_literal: true

module StubSnowplow
  def stub_snowplow
    # WebMock is set up to allow requests to `localhost`
    host = 'localhost'

    stub_application_setting(snowplow_enabled: true, snowplow_collector_hostname: host)

    allow(SnowplowTracker::SelfDescribingJson).to receive(:new).and_call_original
    allow(Gitlab::Tracking).to receive(:event).and_call_original # rubocop:disable RSpec/ExpectGitlabTracking
  end
end
