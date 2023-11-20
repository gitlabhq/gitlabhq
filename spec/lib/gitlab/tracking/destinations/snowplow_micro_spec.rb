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

  describe '#options' do
    let_it_be(:group) { create :group }

    before do
      stub_config(snowplow_micro: snowplow_micro_settings)
    end

    it 'includes protocol with the correct value' do
      expect(subject.options(group)[:protocol]).to eq 'http'
    end

    it 'includes port with the correct value' do
      expect(subject.options(group)[:port]).to eq 9091
    end

    it 'includes forceSecureTracker with value false' do
      expect(subject.options(group)[:forceSecureTracker]).to eq false
    end
  end
end
