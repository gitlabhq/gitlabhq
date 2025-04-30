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

  describe '#hostname' do
    context 'when snowplow_micro config is set' do
      let(:address) { '127.0.0.1:9091' }

      before do
        stub_config(snowplow_micro: snowplow_micro_settings)
      end

      it 'returns proper URI' do
        expect(subject.hostname).to eq('127.0.0.1:9091')
        expect(subject.uri.scheme).to eq('http')
      end

      context 'when gitlab config has https scheme' do
        before do
          stub_config_setting(https: true)
        end

        it 'returns proper URI' do
          expect(subject.hostname).to eq('127.0.0.1:9091')
          expect(subject.uri.scheme).to eq('https')
        end
      end
    end

    context 'when snowplow_micro config is not set' do
      before do
        allow(Gitlab.config).to receive(:snowplow_micro).and_raise(GitlabSettings::MissingSetting)
      end

      it 'returns localhost hostname' do
        expect(subject.hostname).to eq('localhost:9090')
      end
    end
  end

  describe '#snowplow_options' do
    let_it_be(:group) { create :group }

    before do
      stub_config(snowplow_micro: snowplow_micro_settings)
      stub_application_setting(snowplow_enabled?: true)
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

  describe '#frontend_client_options' do
    let_it_be(:group) { create :group }

    before do
      stub_config(snowplow_micro: snowplow_micro_settings)
    end

    context 'when snowplow is enabled' do
      before do
        stub_application_setting(snowplow_enabled?: true)
        stub_feature_flags(additional_snowplow_tracking: true)
      end

      it 'includes snowplow_options with Snowplow micro-specific overrides' do
        expect(subject).to receive(:snowplow_options).with(group).and_call_original

        options = subject.frontend_client_options(group)

        expect(options).to include(
          protocol: 'http',
          port: 9091,
          forceSecureTracker: false
        )
      end
    end

    context 'when snowplow is disabled' do
      before do
        stub_application_setting(snowplow_enabled?: false)
        allow(Gitlab).to receive(:host_with_port).and_return('gitlab.example.com')
        allow(Gitlab.config.gitlab).to receive(:https).and_return(true)
      end

      it 'returns product_usage_events options' do
        expect(subject).not_to receive(:snowplow_options)

        options = subject.frontend_client_options(group)

        expect(options).to include(
          hostname: 'gitlab.example.com',
          postPath: '/-/collect_events',
          forceSecureTracker: true
        )
      end
    end
  end
end
