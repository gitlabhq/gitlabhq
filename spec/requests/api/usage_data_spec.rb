# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::UsageData, feature_category: :service_ping do
  let_it_be(:user) { create(:user) }

  shared_examples 'does not allow web request without CSRF token' do
    it 'returns 401 response when CSRF check fails on web request' do
      allow(Gitlab::RequestForgeryProtection).to receive(:verified?).and_return(false)
      sign_in(user)

      post api(endpoint), params: { event: known_event }

      expect(response).to have_gitlab_http_status(:unauthorized)
    end
  end

  describe 'GET /usage_data/service_ping' do
    let(:endpoint) { '/usage_data/service_ping' }

    context 'without authentication' do
      it 'returns 401 response' do
        get api(endpoint)

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when authenticated as non-admin' do
      let(:user) { create(:user) }

      it 'returns 403' do
        get api(endpoint, user)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when authenticated as an admin using ai_workflows oauth access token' do
      let(:oauth_access_token) { create(:oauth_access_token, user: user, scopes: [:ai_workflows]) }

      before do
        allow(Ability).to receive(:allowed?).and_return(true)
      end

      it 'returns 403' do
        get api(endpoint, oauth_access_token: oauth_access_token)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when authenticated as an admin using read_service_ping access token' do
      let(:scopes) { [Gitlab::Auth::READ_SERVICE_PING_SCOPE] }
      let(:personal_access_token) { create(:personal_access_token, user: user, scopes: scopes) }

      before do
        allow(Ability).to receive(:allowed?).and_return(true)
      end

      it 'returns 200' do
        get api(endpoint, personal_access_token: personal_access_token)

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'returns service ping payload' do
        usage_data = { 'key' => 'value' }
        allow(Rails.cache).to receive(:fetch).and_return(usage_data)

        get api(endpoint, personal_access_token: personal_access_token)

        expect(response.body).to eq(usage_data.to_json)
      end

      it 'tracks an internal event' do
        expect(Gitlab::InternalEvents).to receive(:track_event)
          .with('request_service_ping_via_rest', user: user)

        get api(endpoint, personal_access_token: personal_access_token)
      end
    end
  end

  describe 'POST /usage_data/increment_counter' do
    let(:endpoint) { '/usage_data/increment_counter' }
    let(:known_event) { "diff_searches" }
    let(:unknown_event) { 'unknown' }

    context 'without authentication' do
      it 'returns 401 response' do
        post api(endpoint), params: { event: known_event }

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    include_examples 'does not allow web request without CSRF token'

    context 'with authentication' do
      before do
        stub_application_setting(usage_ping_enabled: true)
      end

      context 'when event is missing from params' do
        it 'returns bad request' do
          post api(endpoint, user), params: {}

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end

      context 'with correct params' do
        it 'returns status :ok' do
          expect(Gitlab::UsageDataCounters::BaseCounter).to receive(:count).with("searches")

          post api(endpoint, user), params: { event: known_event }

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'with unknown event' do
        before do
          skip_default_enabled_yaml_check
        end

        it 'returns status ok' do
          expect(Gitlab::UsageDataCounters::BaseCounter).not_to receive(:count)

          post api(endpoint, user), params: { event: unknown_event }

          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end
  end

  describe 'POST /usage_data/increment_unique_users' do
    let(:endpoint) { '/usage_data/increment_unique_users' }
    let(:known_event) { 'g_compliance_dashboard' }
    let(:unknown_event) { 'unknown' }

    context 'without authentication' do
      it 'returns 401 response' do
        post api(endpoint), params: { event: known_event }

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    include_examples 'does not allow web request without CSRF token'

    context 'with authentication' do
      before do
        stub_application_setting(usage_ping_enabled: true)
      end

      context 'with web authentication but without CSRF token' do
        it 'returns 401 response' do
          allow(Gitlab::RequestForgeryProtection).to receive(:verified?).and_return(false)

          sign_in(user)

          post api(endpoint), params: { event: known_event }

          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end

      context 'when event is missing from params' do
        it 'returns bad request' do
          post api(endpoint, user), params: {}

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end

      context 'with correct params' do
        it 'returns status ok' do
          expect(Gitlab::UsageDataCounters::HLLRedisCounter).to receive(:track).with(anything, known_event, anything)
          # allow other events to also get triggered
          allow(Gitlab::UsageDataCounters::HLLRedisCounter).to receive(:track)

          post api(endpoint, user), params: { event: known_event }

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'with unknown event' do
        it 'returns status ok' do
          expect(Gitlab::Redis::HLL).not_to receive(:add)

          post api(endpoint, user), params: { event: unknown_event }

          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end
  end

  describe 'POST /usage_data/track_event' do
    let(:endpoint) { '/usage_data/track_event' }
    let(:known_event) { 'i_compliance_dashboard' }
    let(:unknown_event) { 'unknown' }
    let(:namespace_id) { 123 }
    let(:project_id) { 123 }

    context 'without authentication' do
      it 'returns 401 response' do
        post api(endpoint), params: { event: known_event, namespace_id: namespace_id, project_id: project_id }

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'with personal access token that has read_service_ping scope' do
      let(:scopes) { [Gitlab::Auth::READ_SERVICE_PING_SCOPE] }
      let(:personal_access_token) { create(:personal_access_token, user: user, scopes: scopes) }
      let(:params) { { event: known_event } }

      it 'returns 403' do
        post api(endpoint, personal_access_token: personal_access_token), params: params

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'with oauth token that has ai_workflows scope' do
      let(:oauth_access_token) { create(:oauth_access_token, user: user, scopes: [:ai_workflows]) }
      let(:params) { { event: known_event } }

      it 'allows access' do
        expect(Gitlab::InternalEvents).to receive(:track_event)
          .with(
            known_event,
            send_snowplow_event: false,
            user: user,
            namespace: nil,
            project: nil,
            additional_properties: {}
          )
        post api(endpoint, oauth_access_token: oauth_access_token), params: params

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'with usage ping enabled' do
      let_it_be(:namespace) { create(:namespace) }
      let_it_be(:project) { create(:project) }
      let_it_be(:additional_properties) do
        {
          label: 'label3',
          property: 'admin',
          lang: 'ruby'
        }
      end

      before do
        stub_application_setting(usage_ping_enabled: true)
      end

      include_examples 'does not allow web request without CSRF token'

      context 'with correct params' do
        it 'returns status ok' do
          expect(Gitlab::InternalEvents).to receive(:track_event)
            .with(
              known_event,
              send_snowplow_event: false,
              user: user,
              namespace: namespace,
              project: project,
              additional_properties: additional_properties
            )

          params = {
            event: known_event,
            namespace_id: namespace.id,
            project_id: project.id,
            additional_properties: additional_properties
          }
          post api(endpoint, user), params: params

          expect(response).to have_gitlab_http_status(:ok)
        end

        context 'with no additional_properties' do
          it 'returns status ok' do
            expect(Gitlab::InternalEvents).to receive(:track_event)
              .with(
                known_event,
                send_snowplow_event: false,
                user: user,
                namespace: namespace,
                project: project,
                additional_properties: {}
              )

            post api(endpoint, user), params: { event: known_event, namespace_id: namespace.id, project_id: project.id }

            expect(response).to have_gitlab_http_status(:ok)
          end
        end
      end

      describe 'send_to_snowplow param' do
        it 'does not send the event to snowplow when send_to_snowplow is false' do
          expect(Gitlab::InternalEvents).to receive(:track_event)
            .with(
              known_event,
              send_snowplow_event: false,
              user: user,
              namespace: namespace,
              project: project,
              additional_properties: additional_properties
            )

          post api(endpoint, user), params: {
            event: known_event,
            namespace_id: namespace.id,
            project_id: project.id,
            additional_properties: additional_properties,
            send_to_snowplow: false
          }

          expect(response).to have_gitlab_http_status(:ok)
        end

        it 'sends event to Snowplow when send_to_snowplow is true' do
          expect(Gitlab::InternalEvents).to receive(:track_event)
            .with(
              known_event,
              send_snowplow_event: true,
              user: user,
              namespace: namespace,
              project: project,
              additional_properties: additional_properties
            )

          post api(endpoint, user), params:
            {
              event: known_event,
              namespace_id: namespace.id,
              project_id: project.id,
              additional_properties: additional_properties,
              send_to_snowplow: true
            }

          expect(response).to have_gitlab_http_status(:ok)
        end

        it 'does not send event to Snowplow by default' do
          expect(Gitlab::InternalEvents).to receive(:track_event)
            .with(
              known_event,
              send_snowplow_event: false,
              user: user,
              namespace: namespace,
              project: project,
              additional_properties: additional_properties
            )

          post api(endpoint, user), params:
            {
              event: known_event,
              namespace_id: namespace.id,
              project_id: project.id,
              additional_properties: additional_properties
            }

          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end
  end

  describe 'POST /usage_data/track_events' do
    let(:endpoint) { '/usage_data/track_events' }
    let(:event) { 'web_ide_viewed' }
    let(:namespace) { create(:namespace) }
    let_it_be(:project) { create(:project) }
    let(:additional_properties) do
      {
        label: 'label3',
        property: 'admin',
        lang: 'ruby'
      }
    end

    context 'without authentication' do
      it 'returns 401 response' do
        post api(endpoint), params: { events: [{ event: event }] }

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'with the amount events greater than the limit' do
      let(:params) { { events: Array.new(API::UsageData::MAXIMUM_TRACKED_EVENTS * 2) { { event: event } } } }

      it 'returns bad request' do
        expect(Gitlab::InternalEvents).not_to receive(:track_event)

        post api(endpoint, user), params: params

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'with correct params' do
      let(:params) do
        {
          events: [
            {
              event: event,
              namespace_id: namespace.id,
              project_id: project.id,
              additional_properties: additional_properties
            }
          ]
        }
      end

      it 'tracks the events' do
        expect(Gitlab::InternalEvents).to receive(:track_event)
                                            .with(
                                              event,
                                              send_snowplow_event: false,
                                              namespace: namespace,
                                              user: user,
                                              project: project,
                                              additional_properties: additional_properties
                                            )

        post api(endpoint, user), params: params
      end

      it 'triggers internal events and returns status ok' do
        allow(Gitlab::InternalEvents).to receive(:track_event)

        post api(endpoint, user), params: params

        expect(response).to have_gitlab_http_status(:ok)
      end

      context 'with incorrect params' do
        let(:params) do
          {
            events: [
              {
                event: 1
              }
            ]
          }
        end

        it 'returns bad request' do
          expect { post(api(endpoint, user), params: params) }
            .not_to trigger_internal_events(event)
        end
      end
    end
  end

  describe 'GET /usage_data/metric_definitions' do
    let(:endpoint) { '/usage_data/metric_definitions' }
    let(:include_paths) { false }
    let(:metrics) do
      {
        'counter.category.event' => metric1,
        'counter.category.event2' => metric2
      }
    end

    let(:metric1_attributes) do
      { 'key_path' => 'counter.category.event', 'description' => 'Metric description', 'tiers' => ['free'] }
    end

    let(:metric2_attributes) do
      { 'key_path' => 'counter.category.event2', 'description' => 'Metric description2', 'tiers' => ['free'] }
    end

    let(:metric1) do
      Gitlab::Usage::MetricDefinition.new('/metrics/test_metric1.yml', metric1_attributes.dup.symbolize_keys)
    end

    let(:metric2) do
      Gitlab::Usage::MetricDefinition.new('/metrics/test_metric2.yml', metric2_attributes.dup.symbolize_keys)
    end

    let(:metric_yaml) do
      [metric1_attributes.merge('tiers' => ['free']), metric2_attributes.merge('tiers' => ['free'])].to_yaml
    end

    before do
      allow(Gitlab::Usage::MetricDefinition).to receive(:definitions).and_return(metrics)
    end

    around do |example|
      Gitlab::Usage::MetricDefinition.instance_variable_set(:@metrics_yaml, nil)
      example.run
      Gitlab::Usage::MetricDefinition.instance_variable_set(:@metrics_yaml, nil)
    end

    context 'without authentication' do
      it 'returns a YAML file', :aggregate_failures do
        get(api(endpoint), params: { include_paths: include_paths })

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.media_type).to eq('application/yaml')
        expect(response.body).to eq(metric_yaml)
      end
    end

    context "without include_paths passed" do
      it 'uses false include_paths by default', :aggregate_failures do
        get(api(endpoint))

        expect(response.body).to eq(metric_yaml)
      end
    end

    it 'returns tiers in the metric attributes', :aggregate_failures do
      get(api(endpoint))

      payload = YAML.safe_load(response.body)
      expect(payload.length).to be 2
      expect(payload[0]).to include(metric1_attributes)
      expect(payload[1]).to include(metric2_attributes)
    end

    context "with include_paths being true" do
      let(:include_paths) { true }

      it 'passes include_paths value', :aggregate_failures do
        get(api(endpoint), params: { include_paths: include_paths })

        payload = YAML.safe_load(response.body)
        expect(payload.length).to be 2
        expect(payload[0]).to include(metric1_attributes)
        expect(payload[0]['file_path']).to end_with('metrics/test_metric1.yml')
        expect(payload[1]).to include(metric2_attributes)
        expect(payload[1]['file_path']).to end_with('metrics/test_metric2.yml')
      end
    end
  end
end
