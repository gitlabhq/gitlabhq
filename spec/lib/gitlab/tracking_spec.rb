# frozen_string_literal: true
require 'spec_helper'

describe Gitlab::Tracking do
  let(:timestamp) { Time.utc(2017, 3, 22) }

  before do
    stub_application_setting(snowplow_enabled: true)
    stub_application_setting(snowplow_collector_hostname: 'gitfoo.com')
    stub_application_setting(snowplow_cookie_domain: '.gitfoo.com')
    stub_application_setting(snowplow_app_id: '_abc123_')
    stub_application_setting(snowplow_iglu_registry_url: 'https://example.org')
  end

  describe '.snowplow_options' do
    it 'returns useful client options' do
      expected_fields = {
        namespace: 'gl',
        hostname: 'gitfoo.com',
        cookieDomain: '.gitfoo.com',
        appId: '_abc123_',
        formTracking: true,
        linkClickTracking: true,
        igluRegistryUrl: 'https://example.org'
      }

      expect(subject.snowplow_options(nil)).to match(expected_fields)
    end

    it 'enables features using feature flags' do
      stub_feature_flags(additional_snowplow_tracking: true)
      allow(Feature).to receive(:enabled?).with(
        :additional_snowplow_tracking,
        '_group_'
      ).and_return(false)
      addition_feature_fields = {
        formTracking: false,
        linkClickTracking: false
      }

      expect(subject.snowplow_options('_group_')).to include(addition_feature_fields)
    end
  end

  describe 'tracking events' do
    shared_examples 'events not tracked' do
      it 'does not track events' do
        stub_application_setting(snowplow_enabled: false)
        expect(SnowplowTracker::AsyncEmitter).not_to receive(:new)
        expect(SnowplowTracker::Tracker).not_to receive(:new)

        track_event
      end
    end

    around do |example|
      Timecop.freeze(timestamp) { example.run }
    end

    before do
      described_class.instance_variable_set("@snowplow", nil)
    end

    let(:tracker) { double }

    def receive_events
      expect(SnowplowTracker::AsyncEmitter).to receive(:new).with(
        'gitfoo.com', { protocol: 'https' }
      ).and_return('_emitter_')

      expect(SnowplowTracker::Tracker).to receive(:new).with(
        '_emitter_',
        an_instance_of(SnowplowTracker::Subject),
        'gl',
        '_abc123_'
      ).and_return(tracker)
    end

    describe '.event' do
      let(:track_event) do
        described_class.event('category', 'action',
          label: '_label_',
          property: '_property_',
          value: '_value_',
          context:  nil
        )
      end

      it_behaves_like 'events not tracked'

      it 'can track events' do
        receive_events
        expect(tracker).to receive(:track_struct_event).with(
          'category',
          'action',
          '_label_',
          '_property_',
          '_value_',
          nil,
          (timestamp.to_f * 1000).to_i
        )

        track_event
      end
    end

    describe '.self_describing_event' do
      let(:track_event) do
        described_class.self_describing_event('iglu:com.gitlab/example/jsonschema/1-0-2',
          {
            foo: 'bar',
            foo_count: 42
          },
          context: nil
        )
      end

      it_behaves_like 'events not tracked'

      it 'can track self describing events' do
        receive_events
        expect(SnowplowTracker::SelfDescribingJson).to receive(:new).with(
          'iglu:com.gitlab/example/jsonschema/1-0-2',
          {
            foo: 'bar',
            foo_count: 42
          }
        ).and_return('_event_json_')

        expect(tracker).to receive(:track_self_describing_event).with(
          '_event_json_',
          nil,
          (timestamp.to_f * 1000).to_i
        )

        track_event
      end
    end
  end
end
