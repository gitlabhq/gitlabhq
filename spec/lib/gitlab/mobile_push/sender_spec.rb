# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::MobilePush::Sender, feature_category: :notifications do
  let_it_be(:user) { create(:user) }

  let(:client) { instance_double(::Gitlab::MobilePush::ApnsClient, close: nil) }
  let(:counter) { instance_double(Prometheus::Client::Counter, increment: nil) }
  let(:payload) { instance_double(::Gitlab::MobilePush::SummaryPayload) }

  subject(:sender) { described_class.new }

  before do
    allow(::Gitlab::MobilePush::ApnsClient).to receive(:new).and_return(client)
    allow(Gitlab::Metrics).to receive(:counter).and_call_original
    allow(Gitlab::Metrics).to receive(:counter)
      .with(:mobile_push_notifications_total, anything)
      .and_return(counter)
  end

  describe '#deliver' do
    it 'pushes the payload yielded for each phone and returns one result per phone' do
      subscriptions = create_list(:mobile_device_push_subscription, 2, user: user)
      allow(client).to receive(:push).and_return(:delivered, :failed)

      results = sender.deliver(subscriptions) { |subscription| [subscription.id, payload] }

      expect(results).to eq([:delivered, :failed])
      expect(client).to have_received(:push).with(subscriptions.first, [subscriptions.first.id, payload])
      expect(client).to have_received(:push).with(subscriptions.last, [subscriptions.last.id, payload])
      expect(counter).to have_received(:increment).with(result: 'delivered')
      expect(counter).to have_received(:increment).with(result: 'failed')
    end

    it 'destroys the subscription and counts an eviction on a dead token' do
      subscription = create(:mobile_device_push_subscription, user: user)
      allow(client).to receive(:push).and_return(:bad_token)

      expect(sender.deliver([subscription]) { payload }).to eq([:bad_token])
      expect(Notifications::MobileDevicePushSubscription.exists?(subscription.id)).to be(false)
      expect(counter).to have_received(:increment).with(result: 'evicted')
    end

    it 'counts a push without APNs credentials as not configured' do
      subscription = create(:mobile_device_push_subscription, user: user)
      allow(client).to receive(:push).and_return(:skipped)

      sender.deliver([subscription]) { payload }

      expect(counter).to have_received(:increment).with(result: 'skipped_not_configured')
    end
  end

  describe '#close' do
    it 'closes the client after a send' do
      subscription = create(:mobile_device_push_subscription, user: user)
      allow(client).to receive(:push).and_return(:delivered)
      sender.deliver([subscription]) { payload }

      sender.close

      expect(client).to have_received(:close)
    end

    it 'opens no client when nothing was sent' do
      sender.close

      expect(::Gitlab::MobilePush::ApnsClient).not_to have_received(:new)
    end
  end
end
