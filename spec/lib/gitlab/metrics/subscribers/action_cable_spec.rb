# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::Subscribers::ActionCable, :request_store do
  let(:subscriber) { described_class.new }
  let(:counter) { double(:counter) }
  let(:data) { { 'result' => { 'data' => { 'event' => 'updated' } } } }
  let(:channel_class) { 'IssuesChannel' }
  let(:event) do
    double(
      :event,
      name: name,
      payload: payload
    )
  end

  describe '#transmit' do
    let(:name) { 'transmit.action_cable' }
    let(:via) { 'streamed from issues:Z2lkOi8vZs2l0bGFiL0lzc3VlLzQ0Ng' }
    let(:payload) do
      {
        channel_class: channel_class,
        via: via,
        data: data
      }
    end

    it 'tracks the transmit event' do
      allow(::Gitlab::Metrics).to receive(:counter).with(
        :action_cable_single_client_transmissions_total, /transmit/
      ).and_return(counter)

      expect(counter).to receive(:increment)

      subscriber.transmit(event)
    end

    it 'tracks size of payload as JSON' do
      allow(::Gitlab::Metrics).to receive(:histogram).with(
        :action_cable_transmitted_bytes, /transmit/
      ).and_return(counter)
      message_size = ::ActiveSupport::JSON.encode(data).bytesize

      expect(counter).to receive(:observe).with({ channel: channel_class, operation: 'event' }, message_size)

      subscriber.transmit(event)
    end
  end

  describe '#broadcast' do
    let(:name) { 'broadcast.action_cable' }
    let(:coder) { ActiveSupport::JSON }
    let(:message) do
      { event: :updated }
    end

    let(:broadcasting) { 'issues:Z2lkOi8vZ2l0bGFiL0lzc3VlLzQ0Ng' }
    let(:payload) do
      {
        broadcasting: broadcasting,
        message: message,
        coder: coder
      }
    end

    it 'tracks the broadcast event' do
      allow(::Gitlab::Metrics).to receive(:counter).with(
        :action_cable_broadcasts_total, /broadcast/
      ).and_return(counter)

      expect(counter).to receive(:increment)

      subscriber.broadcast(event)
    end
  end

  describe '#transmit_subscription_confirmation' do
    let(:name) { 'transmit_subscription_confirmation.action_cable' }
    let(:channel_class) { 'IssuesChannel' }
    let(:payload) do
      {
        channel_class: channel_class
      }
    end

    it 'tracks the subscription confirmation event' do
      allow(::Gitlab::Metrics).to receive(:counter).with(
        :action_cable_subscription_confirmations_total, /confirm/
      ).and_return(counter)

      expect(counter).to receive(:increment)

      subscriber.transmit_subscription_confirmation(event)
    end
  end

  describe '#transmit_subscription_rejection' do
    let(:name) { 'transmit_subscription_rejection.action_cable' }
    let(:channel_class) { 'IssuesChannel' }
    let(:payload) do
      {
          channel_class: channel_class
      }
    end

    it 'tracks the subscription rejection event' do
      allow(::Gitlab::Metrics).to receive(:counter).with(
        :action_cable_subscription_rejections_total, /reject/
      ).and_return(counter)

      expect(counter).to receive(:increment)

      subscriber.transmit_subscription_rejection(event)
    end
  end
end
