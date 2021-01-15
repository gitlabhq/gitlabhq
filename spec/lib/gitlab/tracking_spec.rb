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

    shared_examples 'delegates to destination' do |klass|
      context 'with standard context' do
        it "delegates to #{klass} destination" do
          expect_any_instance_of(klass).to receive(:event) do |_, category, action, args|
            expect(category).to eq('category')
            expect(action).to eq('action')
            expect(args[:label]).to eq('label')
            expect(args[:property]).to eq('property')
            expect(args[:value]).to eq(1.5)
            expect(args[:context].length).to eq(1)
            expect(args[:context].first.to_json[:schema]).to eq(Gitlab::Tracking::StandardContext::GITLAB_STANDARD_SCHEMA_URL)
            expect(args[:context].first.to_json[:data]).to include(foo: 'bar')
          end

          described_class.event('category', 'action', label: 'label', property: 'property', value: 1.5,
                                standard_context: Gitlab::Tracking::StandardContext.new(foo: 'bar'))
        end
      end

      context 'without standard context' do
        it "delegates to #{klass} destination" do
          expect_any_instance_of(klass).to receive(:event) do |_, category, action, args|
            expect(category).to eq('category')
            expect(action).to eq('action')
            expect(args[:label]).to eq('label')
            expect(args[:property]).to eq('property')
            expect(args[:value]).to eq(1.5)
          end

          described_class.event('category', 'action', label: 'label', property: 'property', value: 1.5)
        end
      end
    end

    include_examples 'delegates to destination', Gitlab::Tracking::Destinations::Snowplow
    include_examples 'delegates to destination', Gitlab::Tracking::Destinations::ProductAnalytics
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
