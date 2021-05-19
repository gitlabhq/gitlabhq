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
    let(:namespace) { create(:namespace) }

    shared_examples 'delegates to destination' do |klass|
      before do
        allow_any_instance_of(Gitlab::Tracking::Destinations::Snowplow).to receive(:event)
        allow_any_instance_of(Gitlab::Tracking::Destinations::ProductAnalytics).to receive(:event)
      end

      it "delegates to #{klass} destination" do
        other_context = double(:context)

        project = double(:project)
        user = double(:user)

        expect(Gitlab::Tracking::StandardContext)
          .to receive(:new)
          .with(project: project, user: user, namespace: namespace, extra_key_1: 'extra value 1', extra_key_2: 'extra value 2')
          .and_call_original

        expect_any_instance_of(klass).to receive(:event) do |_, category, action, args|
          expect(category).to eq('category')
          expect(action).to eq('action')
          expect(args[:label]).to eq('label')
          expect(args[:property]).to eq('property')
          expect(args[:value]).to eq(1.5)
          expect(args[:context].length).to eq(2)
          expect(args[:context].first.to_json[:schema]).to eq(Gitlab::Tracking::StandardContext::GITLAB_STANDARD_SCHEMA_URL)
          expect(args[:context].last).to eq(other_context)
        end

        described_class.event('category', 'action', label: 'label', property: 'property', value: 1.5,
                              context: [other_context], project: project, user: user, namespace: namespace,
                              extra_key_1: 'extra value 1', extra_key_2: 'extra value 2')
      end
    end

    it_behaves_like 'delegates to destination', Gitlab::Tracking::Destinations::Snowplow
    it_behaves_like 'delegates to destination', Gitlab::Tracking::Destinations::ProductAnalytics

    it 'tracks errors' do
      expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception).with(
        an_instance_of(ContractError),
        snowplow_category: nil, snowplow_action: 'some_action'
      )

      described_class.event(nil, 'some_action')
    end
  end
end
