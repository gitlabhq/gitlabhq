# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:each, :event_store_publisher) do
    allow(Gitlab::EventStore).to receive(:publish)
  end
end
