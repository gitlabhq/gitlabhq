# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::SnowplowEmitterWorker, feature_category: :product_analytics do
  let(:worker) { described_class.new }
  let(:endpoint) { 'localhost' }
  let(:options) { {} }
  let(:event_batch) { [{ event: 'test_event' }, { event: 'another_event' }] }

  describe '#perform' do
    it 'does not fail if the event batch is empty' do
      expect do
        worker.perform([], endpoint, options)
      end.not_to raise_error
    end

    it 'calls SnowplowEventSender' do
      expect_next_instance_of(Gitlab::Tracking::SnowplowEventSender, {}, endpoint) do |event_service|
        expect(event_service).to receive(:send_events)
      end

      worker.perform(event_batch, endpoint, options)
    end

    it 'logs events with endpoint and event_count' do
      expect(Gitlab::AppLogger).to receive(:info).with(
        message: "Sending snowplow events",
        origin: 'Analytics::SnowplowEmitterWorker',
        endpoint: endpoint,
        events_count: event_batch.size
      )

      worker.perform(event_batch, endpoint, options)
    end
  end
end
