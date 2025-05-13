# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Tracking::SnowplowLoggingEmitter, feature_category: :service_ping do
  let(:emitter) { described_class.new(endpoint: 'test.endpoint', options: { method: 'post' }) }

  describe '#send_requests' do
    it 'logs each event' do
      stub = stub_request(:post, %r{/com.snowplowanalytics.snowplow/tp2})

      event_logger = instance_double(Gitlab::Tracking::SnowplowEventLogger)
      allow(Gitlab::Tracking::SnowplowEventLogger).to receive(:build).and_return(event_logger)
      allow(event_logger).to receive(:info)

      event1 = { event: 'event1' }
      event2 = { event: 'event2' }
      events = [event1, event2]

      emitter.send_requests(events)

      expect(event_logger).to have_received(:info).with(message: 'sending event', payload: '{"event":"event1"}')
      expect(event_logger).to have_received(:info).with(message: 'sending event', payload: '{"event":"event2"}')

      expect(stub).to have_been_requested
    end
  end
end
