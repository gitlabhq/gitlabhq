# frozen_string_literal: true

RSpec.configure do |config|
  config.include SnowplowCaptureHelpers, :capture_snowplow_events

  # Opting out does not disable Snowplow, the hook below turns it back on with the GitLab.com
  # settings. It stops stub_snowplow resetting the collector hostname to localhost, which it
  # would otherwise do after this hook, since spec_helper registers its own hook later.
  config.define_derived_metadata(:capture_snowplow_events) do |metadata|
    metadata[:do_not_stub_snowplow_by_default] = true
  end

  config.before(:example, :capture_snowplow_events) do
    Gitlab::Testing::SnowplowEvents.capture!

    server = Capybara.current_session.server
    raise 'The :capture_snowplow_events tag requires :js, no Capybara server is running' unless server

    # Leaving Snowplow enabled keeps the GitLab.com frontend configuration, where the browser
    # posts to a collector directly rather than through /-/collect_events. Pointing the
    # collector at the Capybara server puts Testing::SnowplowCollectorMiddleware on the other end.
    stub_application_setting(
      snowplow_enabled: true,
      snowplow_app_id: 'gitlab',
      snowplow_collector_hostname: "#{server.host}:#{server.port}"
    )

    # The collector hostname is read once, when the tracker is built.
    Gitlab::Tracking.remove_instance_variable(:@tracker) if Gitlab::Tracking.instance_variable_defined?(:@tracker)
  end

  config.after(:example, :capture_snowplow_events) do
    Gitlab::Testing::SnowplowEvents.stop_capturing!
  end
end
