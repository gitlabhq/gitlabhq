# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EventForward::EventForwardController, feature_category: :product_analytics do
  let(:tracker) { instance_double(Gitlab::Tracking::Destinations::Snowplow) }
  let(:event_eligibility_checker) { instance_double(Gitlab::Tracking::EventEligibilityChecker) }
  let(:logger) { instance_double(Logger) }
  let(:payload) do
    {
      'data' => [
        { 'se_ac' => 'event_1' },
        { 'se_ac' => 'event_2' }
      ]
    }
  end

  before do
    allow(Gitlab::Tracking).to receive(:tracker).and_return(tracker)
    allow(tracker).to receive(:emit_event_payload)
    allow(Gitlab::Tracking::EventEligibilityChecker).to receive(:new).and_return(event_eligibility_checker)
    allow(event_eligibility_checker).to receive(:eligible?).and_return(true)
    allow(EventForward::Logger).to receive(:build).and_return(logger)
    allow(logger).to receive(:info)
    stub_feature_flags(collect_product_usage_events: true)
  end

  describe 'POST #forward' do
    let(:request) { post event_forwarding_path, params: payload, as: :json }

    it 'forwards each event to the Snowplow tracker' do
      payload['data'].each do |event|
        expect(tracker).to receive(:emit_event_payload).with(event)
      end

      request
    end

    it 'logs the number of enqueued events' do
      expect(logger).to receive(:info).with("Enqueued events for forwarding. Count: #{payload['data'].size}")

      request
    end

    it 'returns successful response' do
      request

      expect(response).to have_gitlab_http_status(:ok)
      expect(response.body).to be_empty
    end

    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(collect_product_usage_events: false)
      end

      it 'returns 404 and do not call tracker' do
        expect(tracker).not_to receive(:emit_event_payload)

        request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when filtering events by eligibility' do
      before do
        allow(event_eligibility_checker).to receive(:eligible?).with("event_1").and_return(true)
        allow(event_eligibility_checker).to receive(:eligible?).with("event_2").and_return(false)
      end

      it 'forwards only eligible events to the Snowplow tracker' do
        expect(tracker).to receive(:emit_event_payload).with(payload['data'][0])
        expect(tracker).not_to receive(:emit_event_payload).with(payload['data'][1])

        request
      end

      it 'logs only the number of eligible events' do
        expect(logger).to receive(:info).with("Enqueued events for forwarding. Count: 1")

        request
      end
    end

    context 'when all events are ineligible' do
      before do
        allow(event_eligibility_checker).to receive(:eligible?).and_return(false)
      end

      it 'does not forward any events to the Snowplow tracker' do
        payload['data'].each do |event|
          expect(tracker).not_to receive(:emit_event_payload).with(event)
        end

        request
      end

      it 'logs zero enqueued events' do
        expect(logger).to receive(:info).with("Enqueued events for forwarding. Count: 0")

        request
      end
    end
  end
end
