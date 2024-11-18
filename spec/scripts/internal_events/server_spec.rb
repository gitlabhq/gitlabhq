# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../scripts/internal_events/server'

RSpec.describe Server, feature_category: :service_ping do
  include WaitHelpers

  let(:server) { described_class.new }
  let(:port) { Gitlab::Tracking::Destinations::SnowplowMicro.new.uri.port }
  let(:events) { server.events }

  let!(:thread) { Thread.new { server.start } }

  # rubocop:disable RSpec/ExpectOutput -- silencing output, not asserting on it
  before do
    $stderr = StringIO.new
    stub_env('VERIFY_TRACKING', true)
    allow(Addrinfo).to receive(:getaddrinfo).and_call_original
  end

  after do
    thread.exit
    $stderr = STDERR
  end
  # rubocop:enable RSpec/ExpectOutput

  describe 'GET /i -> trigger a single event provided through query params (backend)' do
    subject(:response) { await { Net::HTTP.get_response url_for("/i?#{query_params}") } }

    context 'with an internal event' do
      let(:query_params) { internal_event_fixture('snowplow_events/internal_event_query_params') }
      let(:context) { internal_event_fixture('snowplow_events/internal_event_query_params_decoded.json') }
      let(:expected_event) do
        {
          event: {
            se_category: 'InternalEventTracking',
            se_action: 'g_project_management_issue_created',
            collector_tstamp: '1727475117074',
            se_label: nil,
            se_property: nil,
            se_value: nil,
            contexts: Gitlab::Json.parse(context)
          },
          rawEvent: { parameters: Rack::Utils.parse_query(query_params) }
        }
      end

      it 'successfully parses event', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/498775' do
        expect(response.code).to eq('200')
        expect(events).to contain_exactly(expected_event)
      end
    end

    # This case is unexpected in practice, but can be helpful to handle during dev on the server
    # Triggerable in console with `Gitlab::Tracking::Destinations::SnowplowMicro.new.event('category', 'action')`
    context 'with a non-internal event without context key' do
      let(:query_params) { internal_event_fixture('snowplow_events/non_internal_event_without_context') }
      let(:expected_event) do
        {
          event: {
            se_category: 'category',
            se_action: 'super_action_thing',
            collector_tstamp: '1727476712646',
            se_label: nil,
            se_property: nil,
            se_value: nil,
            contexts: nil
          },
          rawEvent: { parameters: Rack::Utils.parse_query(query_params) }
        }
      end

      it 'successfully parses event', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/498776' do
        expect(response.code).to eq('200')
        expect(events).to contain_exactly(expected_event)
      end
    end
  end

  describe 'POST /com.snowplowanalytics.snowplow/tp2 -> trigger events provided through request body (frontend)' do
    subject(:response) { await { Net::HTTP.post url_for('/com.snowplowanalytics.snowplow/tp2'), body } }

    context 'when triggered on-click' do
      let(:body) { internal_event_fixture('snowplow_events/internal_event_on_click.json') }
      let(:context) { internal_event_fixture('snowplow_events/internal_event_on_click_decoded.json') }
      let(:expected_event) do
        {
          event: {
            se_category: 'projects:blob:show',
            se_action: 'click_blame_control_on_blob_page',
            collector_tstamp: '1727474524024',
            se_label: nil,
            se_property: nil,
            se_value: nil,
            contexts: Gitlab::Json.parse(context)
          },
          rawEvent: { parameters: Gitlab::Json.parse(body)['data'].first }
        }
      end

      it 'successfully parses event', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/499957' do
        expect(response.code).to eq('200')
        expect(events).to contain_exactly(expected_event)
      end
    end

    context 'when triggered on-load in a batch' do
      let(:body) { internal_event_fixture('snowplow_events/internal_event_on_load_batched.json') }
      let(:context_1) { internal_event_fixture('snowplow_events/internal_event_on_load_batched_decoded_1.json') }
      let(:context_2) { internal_event_fixture('snowplow_events/internal_event_on_load_batched_decoded_2.json') }
      let(:expected_events) do
        [
          {
            event: {
              se_category: 'admin:dashboard:index',
              se_action: 'view_admin_dashboard_pageload',
              collector_tstamp: '1727473513835',
              se_label: nil,
              se_property: nil,
              se_value: nil,
              contexts: Gitlab::Json.parse(context_1)
            },
            rawEvent: { parameters: Gitlab::Json.parse(body)['data'].first }
          },
          {
            event: {
              se_category: 'admin:dashboard:index',
              se_action: 'render',
              collector_tstamp: '1727473513837',
              se_label: 'version_badge',
              se_property: 'Up to date',
              se_value: nil,
              contexts: Gitlab::Json.parse(context_2)
            },
            rawEvent: { parameters: Gitlab::Json.parse(body)['data'].last }
          }
        ]
      end

      it 'successfully parses event', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/498772' do
        expect(response.code).to eq('200')
        expect(events).to match_array(expected_events)
      end
    end

    context 'with a structured event but not an internal event' do
      let(:body) { internal_event_fixture('snowplow_events/non_internal_event.json') }
      let(:context) { internal_event_fixture('snowplow_events/non_internal_event_decoded.json') }
      let(:expected_event) do
        {
          event: {
            se_category: 'admin:dashboard:index',
            se_action: 'render',
            collector_tstamp: '1727473512782',
            se_label: 'version_badge',
            se_property: 'Up to date',
            se_value: nil,
            contexts: Gitlab::Json.parse(context)
          },
          rawEvent: { parameters: Gitlab::Json.parse(body)['data'].first }
        }
      end

      it 'successfully parses event', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/498773' do
        expect(response.code).to eq('200')
        expect(events).to contain_exactly(expected_event)
      end
    end

    context 'with a non-structured event or an internal event' do
      let(:body) { internal_event_fixture('snowplow_events/non_internal_event_structured.json') }

      it 'ignores the event', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/498774' do
        expect(response.code).to eq('200')
        expect(events).to be_empty
      end
    end
  end

  describe 'OPTIONS /com.snowplowanalytics.snowplow/tp2' do
    subject(:response) do
      await { Net::HTTP.new('localhost', port).options('/com.snowplowanalytics.snowplow/tp2') }
    end

    it 'applies the correct headers', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/498779' do
      expect(response.code).to eq('200')
      expect(response.header['Access-Control-Allow-Credentials']).to eq('true')
      expect(response.header['Access-Control-Allow-Headers']).to eq('Content-Type')
      expect(response.header['Access-Control-Allow-Origin']).to eq(Gitlab.config.gitlab.url)
    end
  end

  describe 'GET /micro/good -> list tracked structured events' do
    subject(:response) { await { Net::HTTP.get_response url_for("/micro/good") } }

    it 'successfully returns tracked events', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/498777' do
      expect(response.code).to eq('200')
      expect(response.body).to eq("[]")
    end

    context 'with tracked events' do
      let(:query_params) { internal_event_fixture('snowplow_events/non_internal_event_without_context') }

      before do
        await { Net::HTTP.get url_for("/i?#{query_params}") }
      end

      it 'successfully returns tracked events', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/498778' do
        expect(response.code).to eq('200')
        expect(response.body).to eq([{
          event: {
            se_category: 'category',
            se_action: 'super_action_thing',
            collector_tstamp: '1727476712646',
            se_label: nil,
            se_property: nil,
            se_value: nil,
            contexts: nil
          },
          rawEvent: { parameters: Rack::Utils.parse_query(query_params) }
        }].to_json)
      end
    end
  end

  private

  def await
    wait_for('server response to be available', max_wait_time: 2.seconds) do
      yield
    rescue Errno::ECONNREFUSED, Errno::EADDRNOTAVAIL
      nil
    end
  end

  def url_for(path)
    URI.parse("http://localhost:#{port}#{path}")
  end

  def internal_event_fixture(filepath)
    File.read(Rails.root.join('spec', 'fixtures', 'scripts', 'internal_events', filepath)).chomp
  end
end
