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
    let(:editor_telemetry_header) { { 'X-GitLab-Editor-Telemetry' => '1' } }
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

    context 'when X-GitLab-Editor-Telemetry header is present' do
      let(:request) { post event_forwarding_path, params: payload, as: :json, headers: editor_telemetry_header }

      context 'when unauthenticated' do
        it 'injects gitlab_standard context with null user identity' do
          expect(tracker).to receive(:emit_event_payload).at_least(:once) do |event|
            cx = Gitlab::Json.safe_parse(Base64.decode64(event['cx']))
            standard = cx['data'].find do |c|
              c['schema'] == Gitlab::Tracking::StandardContext::GITLAB_STANDARD_SCHEMA_URL
            end

            expect(standard).not_to be_nil
            expect(standard['data']['user_id']).to be_nil
            expect(standard['data']['global_user_id']).to be_nil
          end

          request
        end
      end

      context 'when authenticated with a personal access token' do
        let(:user) { create(:user) }
        let(:pat) { create(:personal_access_token, user: user) }
        let(:request) do
          post event_forwarding_path, params: payload, as: :json,
            headers: editor_telemetry_header.merge('Private-Token' => pat.token)
        end

        it 'injects gitlab_standard context with user identity populated' do
          expect(tracker).to receive(:emit_event_payload).at_least(:once) do |event|
            cx = Gitlab::Json.safe_parse(Base64.decode64(event['cx']))
            standard = cx['data'].find do |c|
              c['schema'] == Gitlab::Tracking::StandardContext::GITLAB_STANDARD_SCHEMA_URL
            end

            expect(standard['data']['user_id']).not_to be_nil
            expect(standard['data']['global_user_id']).not_to be_nil
          end

          request
        end
      end

      context 'when authenticated with an OAuth token' do
        let(:user) { create(:user) }
        let(:oauth_token) { create(:oauth_access_token, resource_owner: user) }
        let(:request) do
          post event_forwarding_path, params: payload, as: :json,
            headers: editor_telemetry_header.merge('Authorization' => "Bearer #{oauth_token.plaintext_token}")
        end

        it 'injects gitlab_standard context with user identity populated' do
          expect(tracker).to receive(:emit_event_payload).at_least(:once) do |event|
            cx = Gitlab::Json.safe_parse(Base64.decode64(event['cx']))
            standard = cx['data'].find do |c|
              c['schema'] == Gitlab::Tracking::StandardContext::GITLAB_STANDARD_SCHEMA_URL
            end

            expect(standard['data']['user_id']).not_to be_nil
            expect(standard['data']['global_user_id']).not_to be_nil
          end

          request
        end
      end

      context 'when event already has gitlab_standard context' do
        let(:existing_standard_cx) do
          Base64.strict_encode64(Gitlab::Json.dump(
            'schema' => 'iglu:com.snowplowanalytics.snowplow/contexts/jsonschema/1-0-1',
            'data' => [{ 'schema' => Gitlab::Tracking::StandardContext::GITLAB_STANDARD_SCHEMA_URL, 'data' => {} }]
          ))
        end

        let(:event_1) { { 'se_ac' => 'event_1', 'aid' => 'app_id_1', 'cx' => existing_standard_cx } }

        it 'does not inject a duplicate gitlab_standard context' do
          expect(tracker).to receive(:emit_event_payload).at_least(:once) do |event|
            cx = Gitlab::Json.safe_parse(Base64.decode64(event['cx']))
            standard_entries = cx['data'].select do |c|
              c['schema'] == Gitlab::Tracking::StandardContext::GITLAB_STANDARD_SCHEMA_URL
            end

            expect(standard_entries.count).to eq(1)
          end

          request
        end
      end

      context 'when event cx contains invalid JSON' do
        let(:event_1) do
          { 'se_ac' => 'event_1', 'aid' => 'app_id_1', 'cx' => Base64.strict_encode64('not valid json {{{') }
        end

        it 'still forwards the event and returns ok' do
          expect(tracker).to receive(:emit_event_payload).at_least(:once)

          request

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'when event has existing cx without gitlab_standard' do
        let(:other_context) { { 'schema' => 'iglu:com.example/test/jsonschema/1-0-0', 'data' => { 'key' => 'value' } } }
        let(:existing_cx) do
          Base64.strict_encode64(Gitlab::Json.dump(
            'schema' => 'iglu:com.snowplowanalytics.snowplow/contexts/jsonschema/1-0-0',
            'data' => [other_context]
          ))
        end

        let(:event_1) { { 'se_ac' => 'event_1', 'aid' => 'app_id_1', 'cx' => existing_cx } }

        it 'preserves existing contexts and appends gitlab_standard' do
          payload['data'] = [event_1]

          expect(tracker).to receive(:emit_event_payload).once do |event|
            cx = Gitlab::Json.safe_parse(Base64.decode64(event['cx']))

            expect(cx['data']).to include(hash_including('schema' => other_context['schema']))
            expect(cx['data']).to include(hash_including(
              'schema' => Gitlab::Tracking::StandardContext::GITLAB_STANDARD_SCHEMA_URL)
                                         )
          end

          request
        end
      end
    end

    describe 'context validation' do
      let(:validator) { instance_double(Gitlab::Tracking::Destinations::SnowplowContextValidator) }
      let(:context_data) { [{ 'schema' => 'iglu:com.gitlab/test/jsonschema/1-0-0', 'data' => { 'key' => 'value' } }] }
      let(:encoded_context) { Base64.encode64({ 'data' => context_data }.to_json) }
      let(:event_with_context) { { 'se_ac' => 'event_1', 'aid' => 'app_id_1', 'cx' => encoded_context } }

      before do
        allow(Gitlab::Tracking::Destinations::SnowplowContextValidator).to receive(:new).and_return(validator)
        allow(validator).to receive(:validate!)
        payload['data'] = [event_with_context]
      end

      context 'when in development environment' do
        before do
          allow(Rails.env).to receive(:development?).and_return(true)
        end

        it 'validates the context' do
          expect(validator).to receive(:validate!).with(context_data)

          request
        end

        context 'when validation fails' do
          before do
            allow(validator).to receive(:validate!).and_raise(ArgumentError)
          end

          it 'payload still sent to the emitter' do
            expect(tracker).to receive(:emit_event_payload)

            suppress(ArgumentError) { request }
          end
        end
      end

      context 'when not in development environment' do
        before do
          allow(Rails.env).to receive(:development?).and_return(false)
        end

        it 'does not validate the context' do
          expect(validator).not_to receive(:validate!)

          request
        end
      end

      context 'when event does not have cx field' do
        before do
          allow(Rails.env).to receive(:development?).and_return(true)
          payload['data'] = [event_1]
        end

        it 'does not validate the context' do
          expect(validator).not_to receive(:validate!)

          request
        end
      end
    end
  end
end
