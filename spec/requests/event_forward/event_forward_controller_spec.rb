# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EventForward::EventForwardController, feature_category: :product_analytics do
  let(:tracker) { instance_double(Gitlab::Tracking::Destinations::Snowplow) }
  let(:event_eligibility_checker) { instance_double(Gitlab::Tracking::EventEligibilityChecker) }
  let(:logger) { instance_double(Logger) }
  let(:event_1) { { 'se_ac' => 'event_1', 'aid' => 'app_id_1' } }
  let(:event_2) { { 'se_ac' => 'event_2', 'aid' => 'app_id_2' } }
  let(:payload) do
    {
      'data' => [
        event_1,
        event_2
      ]
    }
  end

  before do
    allow(Gitlab::Tracking).to receive(:tracker).and_return(tracker)
    allow(tracker).to receive_messages(emit_event_payload: nil, hostname: 'localhost')
    allow(Gitlab::Tracking::EventEligibilityChecker).to receive(:new).and_return(event_eligibility_checker)
    allow(event_eligibility_checker).to receive(:eligible?).and_return(true)
    allow(EventForward::Logger).to receive(:build).and_return(logger)
    allow(logger).to receive(:info)
  end

  describe 'POST #forward' do
    let(:request) { post event_forwarding_path, params: payload, as: :json }

    context 'when the payload is more than 10 megabytes' do
      let(:event_2) { { 'se_ac' => 'a' * 11_000_000, 'aid' => 'app_id_2' } }

      it 'responds with 400 bad request' do
        expect(tracker).not_to receive(:emit_event_payload)

        request

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'when instance type is dedicated' do
      before do
        stub_application_setting(gitlab_dedicated_instance?: true)
      end

      it 'forwards each event to the Snowplow tracker with updated app_id' do
        payload['data'].each do |event|
          expected_event = event.merge('aid' => "#{event['aid']}_dedicated")

          expect(tracker).to receive(:emit_event_payload).with(expected_event)
        end

        request
      end
    end

    context 'when instance type is self-managed' do
      before do
        stub_application_setting(gitlab_dedicated_instance?: false)
      end

      it 'forwards each event to the Snowplow tracker with updated app_id' do
        payload['data'].each do |event|
          expected_event = event.merge('aid' => "#{event['aid']}_sm")

          expect(tracker).to receive(:emit_event_payload).with(expected_event)
        end

        request
      end
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

    context 'when filtering events by eligibility' do
      before do
        allow(event_eligibility_checker).to receive(:eligible?).with("event_1", "app_id_1").and_return(true)
        allow(event_eligibility_checker).to receive(:eligible?).with("event_2", "app_id_2").and_return(false)
        stub_application_setting(gitlab_dedicated_instance?: true)
      end

      it 'forwards only eligible events to the Snowplow tracker with updated app_id' do
        expected_event = event_1.merge('aid' => 'app_id_1_dedicated')

        expect(tracker).to receive(:emit_event_payload).with(expected_event)
        expect(tracker).not_to receive(:emit_event_payload).with(event_2)

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

    context 'when events have no app_id' do
      let(:event_1) { { 'se_ac' => 'event_1' } }
      let(:event_2) { { 'se_ac' => 'event_2' } }

      it 'forwards each event to the Snowplow tracker' do
        payload['data'].each do |event|
          expect(tracker).to receive(:emit_event_payload).with(event)
        end

        request
      end
    end

    context 'when app_id already has the suffix' do
      let(:event_1) { { 'se_ac' => 'event_1', 'aid' => 'app_id_sm' } }
      let(:event_2) { { 'se_ac' => 'event_2', 'aid' => 'app_id_sm' } }

      it 'forwards each event to the Snowplow tracker' do
        payload['data'].each do |event|
          expect(tracker).to receive(:emit_event_payload).with(event)
        end

        request
      end
    end
  end
end
