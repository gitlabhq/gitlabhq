# frozen_string_literal: true

RSpec.configure do |config|
  # Feature specs call webmock_enable_with_http_connect_on_start!  by
  # default. This is needed to prevent Kubeclient from connecting to a
  # host before the request is stubbed.
  config.before(:each, :kubeclient) do
    webmock_enable!
  end
end
