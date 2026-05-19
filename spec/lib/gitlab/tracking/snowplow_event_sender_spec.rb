# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Tracking::SnowplowEventSender, feature_category: :product_analytics do
  let(:endpoint) { 'localhost' }
  let(:options) { { 'buffer_size' => 1 } }
  let(:service) { described_class.new(options, endpoint) }
  let(:event_batch) do
    [
      { event: 'page_view' },
      { event: 'click' }
    ]
  end

  describe '#initialize' do
    it 'stores the options with indifferent access' do
      expect(service.options[:buffer_size]).to eq(1)
    end
  end

  describe '#send_events' do
    let(:emitter_double) { double }

    before do
      allow(SnowplowTracker::Emitter).to receive(:new).and_return(emitter_double)
      allow(emitter_double).to receive(:send_requests)
    end

    it 'creates an emitter with the correct endpoint' do
      service.send_events(event_batch)

      expect(SnowplowTracker::Emitter).to have_received(:new).with(
        endpoint: endpoint,
        options: hash_including(buffer_size: 1)
      )
    end

    it 'calls send_requests on the emitter with the event batch' do
      service.send_events(event_batch)

      expect(emitter_double).to have_received(:send_requests).with(event_batch)
    end
  end

  describe '#emitter_options' do
    let(:emitter_options) { service.send(:emitter_options) }

    it 'includes the original options item' do
      expect(emitter_options).to include(buffer_size: 1)
    end

    it 'includes on_success callback' do
      expect(emitter_options).to have_key(:on_success)
      expect(emitter_options[:on_success]).to be_a(Method)
    end

    it 'includes on_failure callback' do
      expect(emitter_options).to have_key(:on_failure)
      expect(emitter_options[:on_failure]).to be_a(Method)
    end
  end

  describe '#hostname' do
    it 'returns the endpoint' do
      expect(service.send(:hostname)).to eq(endpoint)
    end
  end

  describe 'metric logging inclusion' do
    it 'includes SnowplowEventMetricLogger' do
      expect(described_class.included_modules).to include(Gitlab::Tracking::Helpers::SnowplowEventMetricLogger)
    end
  end
end
