# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Tracking::Destinations::SnowplowMicro do
  include StubENV

  before do
    stub_application_setting(snowplow_enabled: true)
    stub_env('SNOWPLOW_MICRO_ENABLE', '1')
    allow(Rails.env).to receive(:development?).and_return(true)
  end

  describe '#hostname' do
    context 'when SNOWPLOW_MICRO_URI is set' do
      before do
        stub_env('SNOWPLOW_MICRO_URI', 'http://gdk.test:9091')
      end

      it 'returns hostname URI part' do
        expect(subject.hostname).to eq('gdk.test:9091')
      end
    end

    context 'when SNOWPLOW_MICRO_URI is without protocol' do
      before do
        stub_env('SNOWPLOW_MICRO_URI', 'gdk.test:9091')
      end

      it 'returns hostname URI part' do
        expect(subject.hostname).to eq('gdk.test:9091')
      end
    end

    context 'when SNOWPLOW_MICRO_URI is hostname only' do
      before do
        stub_env('SNOWPLOW_MICRO_URI', 'uriwithoutport')
      end

      it 'returns hostname URI with default HTTP port' do
        expect(subject.hostname).to eq('uriwithoutport:80')
      end
    end

    context 'when SNOWPLOW_MICRO_URI is not set' do
      it 'returns localhost hostname' do
        expect(subject.hostname).to eq('localhost:9090')
      end
    end
  end
end
