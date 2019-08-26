# frozen_string_literal: true
require 'spec_helper'

describe Gitlab::Tracking do
  let(:timestamp) { Time.utc(2017, 3, 22) }

  before do
    stub_application_setting(snowplow_enabled: true)
    stub_application_setting(snowplow_collector_hostname: 'gitfoo.com')
    stub_application_setting(snowplow_cookie_domain: '.gitfoo.com')
    stub_application_setting(snowplow_site_id: '_abc123_')
  end

  describe '.snowplow_options' do
    subject(&method(:described_class))

    it 'returns useful client options' do
      expect(subject.snowplow_options(nil)).to eq(
        namespace: 'gl',
        hostname: 'gitfoo.com',
        cookieDomain: '.gitfoo.com',
        appId: '_abc123_',
        pageTrackingEnabled: true,
        activityTrackingEnabled: true
      )
    end

    it 'enables features using feature flags' do
      stub_feature_flags(additional_snowplow_tracking: true)
      allow(Feature).to receive(:enabled?).with(
        :additional_snowplow_tracking,
        '_group_'
      ).and_return(false)

      expect(subject.snowplow_options('_group_')).to include(
        pageTrackingEnabled: false,
        activityTrackingEnabled: false
      )
    end
  end

  describe '.event' do
    subject(&method(:described_class))

    around do |example|
      Timecop.freeze(timestamp) { example.run }
    end

    it 'can track events' do
      tracker = double

      expect(SnowplowTracker::Emitter).to receive(:new).with(
        'gitfoo.com'
      ).and_return('_emitter_')

      expect(SnowplowTracker::Tracker).to receive(:new).with(
        '_emitter_',
        an_instance_of(SnowplowTracker::Subject),
        'gl',
        '_abc123_'
      ).and_return(tracker)

      expect(tracker).to receive(:track_struct_event).with(
        'category',
        'action',
        '_label_',
        '_property_',
        '_value_',
        '_context_',
        timestamp.to_i
      )

      subject.event('category', 'action',
        label: '_label_',
        property: '_property_',
        value: '_value_',
        context: '_context_'
      )
    end

    it 'does not track when not enabled' do
      stub_application_setting(snowplow_enabled: false)
      expect(SnowplowTracker::Tracker).not_to receive(:new)

      subject.event('epics', 'action', property: 'what', value: 'doit')
    end
  end
end
