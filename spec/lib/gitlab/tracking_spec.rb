# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::Tracking do
  before do
    stub_application_setting(snowplow_enabled: true)
    stub_application_setting(snowplow_collector_hostname: 'gitfoo.com')
    stub_application_setting(snowplow_cookie_domain: '.gitfoo.com')
    stub_application_setting(snowplow_app_id: '_abc123_')

    described_class.instance_variable_set("@snowplow", nil)
  end

  describe '.snowplow_options' do
    it 'returns useful client options' do
      expected_fields = {
        namespace: 'gl',
        hostname: 'gitfoo.com',
        cookieDomain: '.gitfoo.com',
        appId: '_abc123_',
        formTracking: true,
        linkClickTracking: true
      }

      expect(subject.snowplow_options(nil)).to match(expected_fields)
    end

    it 'when feature flag is disabled' do
      stub_feature_flags(additional_snowplow_tracking: false)

      expect(subject.snowplow_options(nil)).to include(
        formTracking: false,
        linkClickTracking: false
      )
    end
  end

  describe '.event' do
    before do
      allow_any_instance_of(Gitlab::Tracking::Destinations::Snowplow).to receive(:event)
      allow_any_instance_of(Gitlab::Tracking::Destinations::ProductAnalytics).to receive(:event)
    end

    it 'delegates to snowplow destination' do
      expect_any_instance_of(Gitlab::Tracking::Destinations::Snowplow)
        .to receive(:event)
        .with('category', 'action', label: 'label', property: 'property', value: 1.5, context: nil)

      described_class.event('category', 'action', label: 'label', property: 'property', value: 1.5)
    end

    it 'delegates to ProductAnalytics destination' do
      expect_any_instance_of(Gitlab::Tracking::Destinations::ProductAnalytics)
        .to receive(:event)
        .with('category', 'action', label: 'label', property: 'property', value: 1.5, context: nil)

      described_class.event('category', 'action', label: 'label', property: 'property', value: 1.5)
    end
  end

  describe '.self_describing_event' do
    it 'delegates to snowplow destination' do
      expect_any_instance_of(Gitlab::Tracking::Destinations::Snowplow)
        .to receive(:self_describing_event)
        .with('iglu:com.gitlab/foo/jsonschema/1-0-0', data: { foo: 'bar' }, context: nil)

      described_class.self_describing_event('iglu:com.gitlab/foo/jsonschema/1-0-0', data: { foo: 'bar' })
    end
  end
end
