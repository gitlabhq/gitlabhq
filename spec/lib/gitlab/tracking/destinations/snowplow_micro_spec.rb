# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Tracking::Destinations::SnowplowMicro, feature_category: :application_instrumentation do
  include StubENV

  let(:snowplow_micro_settings) do
    {
      enabled: true,
      address: address
    }
  end

  let(:address) { "gdk.test:9091" }

  before do
    allow(Rails.env).to receive(:development?).and_return(true)
  end

  it { is_expected.to delegate_method(:flush).to(:tracker) }

  describe '#snowplow_options' do
    let_it_be(:group) { create :group }

    before do
      stub_config(snowplow_micro: snowplow_micro_settings)
    end

    it 'adds Snowplow micro specific options to the parent Snowplow options' do
      base_options = {
        namespace: 'gl',
        hostname: subject.hostname,
        cookieDomain: '.gitlab.com',
        appId: nil,
        formTracking: true,
        linkClickTracking: true
      }

      allow_next_instance_of(Gitlab::Tracking::Destinations::Snowplow) do |snowplow_instance|
        allow(snowplow_instance).to receive(:snowplow_options).with(group).and_return(base_options)
      end

      options = subject.snowplow_options(group)

      expect(options).to include(
        protocol: 'http',
        port: 9091,
        forceSecureTracker: false
      )
      expect(options).to include(base_options)
    end
  end
end
