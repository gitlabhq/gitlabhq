# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Tracking::Destinations::DestinationConfiguration, feature_category: :application_instrumentation do
  include StubENV

  describe '.snowplow_configuration' do
    subject(:configuration) { described_class.snowplow_configuration }

    context 'when snowplow is enabled' do
      before do
        stub_application_setting(snowplow_enabled?: true)
        stub_application_setting(snowplow_collector_hostname: 'gitfoo.com')
      end

      it 'returns configuration with snowplow collector hostname' do
        expect(configuration.hostname).to eq('gitfoo.com')
        expect(configuration.protocol).to eq('https')
        expect(configuration.uri).to be_a(URI::Generic)
      end
    end

    context 'when snowplow is disabled' do
      before do
        stub_application_setting(snowplow_enabled?: false)
      end

      context 'with use_staging_endpoint_for_product_usage_events FF disabled' do
        before do
          stub_feature_flags(use_staging_endpoint_for_product_usage_events: false)
        end

        it 'returns configuration with production endpoint' do
          expect(configuration.hostname).to eq('events.gitlab.net')
          expect(configuration.protocol).to eq('https')
          expect(configuration.uri.to_s).to eq(described_class::PRODUCT_USAGE_EVENT_COLLECT_ENDPOINT)
        end
      end

      context 'with use_staging_endpoint_for_product_usage_events FF enabled' do
        before do
          stub_feature_flags(use_staging_endpoint_for_product_usage_events: true)
        end

        it 'returns configuration with staging endpoint' do
          expect(configuration.hostname).to eq('events-stg.gitlab.net')
          expect(configuration.protocol).to eq('https')
          expect(configuration.uri.to_s).to eq(described_class::PRODUCT_USAGE_EVENT_COLLECT_ENDPOINT_STG)
        end
      end
    end
  end

  describe '.snowplow_micro_configuration' do
    subject(:configuration) { described_class.snowplow_micro_configuration }

    context 'when snowplow_micro config is set' do
      let(:snowplow_micro_settings) do
        {
          enabled: true,
          address: '127.0.0.1:9091'
        }
      end

      before do
        stub_config(snowplow_micro: snowplow_micro_settings)
      end

      it 'returns configuration with snowplow micro URI' do
        expect(configuration.hostname).to eq('127.0.0.1:9091')
        expect(configuration.port).to eq(9091)
        expect(configuration.protocol).to eq('http')
      end

      context 'when gitlab config has https scheme' do
        before do
          stub_config_setting(https: true)
        end

        it 'returns configuration with https scheme' do
          expect(configuration.hostname).to eq('127.0.0.1:9091')
          expect(configuration.protocol).to eq('https')
        end
      end
    end

    context 'when snowplow_micro config is not set' do
      before do
        allow(Gitlab.config).to receive(:snowplow_micro).and_raise(GitlabSettings::MissingSetting)
      end

      it 'returns configuration with default localhost URI' do
        expect(configuration.hostname).to eq('localhost:9090')
        expect(configuration.port).to eq(9090)
        expect(configuration.protocol).to eq('http')
        expect(configuration.uri.to_s).to eq(described_class::SNOWPLOW_MICRO_DEFAULT_URI)
      end
    end
  end

  describe '#initialize' do
    let(:uri) { URI('https://example.com:8080') }

    subject(:configuration) { described_class.new(uri) }

    it 'sets the URI' do
      expect(configuration.uri).to eq(uri)
    end
  end

  describe '#hostname' do
    context 'when URI has no explicit port' do
      context 'with HTTPS scheme' do
        let(:uri) { URI('https://example.com') }

        subject(:configuration) { described_class.new(uri) }

        it 'returns just the host (implicit port 443)' do
          expect(configuration.hostname).to eq('example.com')
          expect(uri.port).to eq(443) # Verify URI sets default port
        end
      end

      context 'with HTTP scheme' do
        let(:uri) { URI('http://example.com') }

        subject(:configuration) { described_class.new(uri) }

        it 'returns just the host (implicit port 80)' do
          expect(configuration.hostname).to eq('example.com')
          expect(uri.port).to eq(80) # Verify URI sets default port
        end
      end
    end

    context 'when URI has explicit default ports' do
      context 'with HTTPS and explicit port 443' do
        let(:uri) { URI('https://example.com:443') }

        subject(:configuration) { described_class.new(uri) }

        it 'returns just the host without port' do
          expect(configuration.hostname).to eq('example.com')
        end
      end

      context 'with HTTP and explicit port 80' do
        let(:uri) { URI('http://example.com:80') }

        subject(:configuration) { described_class.new(uri) }

        it 'returns just the host without port' do
          expect(configuration.hostname).to eq('example.com')
        end
      end
    end

    context 'when URI has non-default ports' do
      context 'with HTTPS and custom port' do
        let(:uri) { URI('https://example.com:8080') }

        subject(:configuration) { described_class.new(uri) }

        it 'returns host with port' do
          expect(configuration.hostname).to eq('example.com:8080')
        end
      end

      context 'with HTTP and custom port' do
        let(:uri) { URI('http://example.com:9090') }

        subject(:configuration) { described_class.new(uri) }

        it 'returns host with port' do
          expect(configuration.hostname).to eq('example.com:9090')
        end
      end

      context 'with HTTPS using HTTP default port' do
        let(:uri) { URI('https://example.com:80') }

        subject(:configuration) { described_class.new(uri) }

        it 'returns host with port (80 is not default for HTTPS)' do
          expect(configuration.hostname).to eq('example.com:80')
        end
      end

      context 'with HTTP using HTTPS default port' do
        let(:uri) { URI('http://example.com:443') }

        subject(:configuration) { described_class.new(uri) }

        it 'returns host with port (443 is not default for HTTP)' do
          expect(configuration.hostname).to eq('example.com:443')
        end
      end
    end
  end

  describe '#port' do
    context 'when URI has explicit port' do
      let(:uri) { URI('https://example.com:8080') }

      subject(:configuration) { described_class.new(uri) }

      it 'returns the explicit port from URI' do
        expect(configuration.port).to eq(8080)
      end
    end

    context 'when URI has implicit default ports' do
      context 'with HTTPS scheme' do
        let(:uri) { URI('https://example.com') }

        subject(:configuration) { described_class.new(uri) }

        it 'returns the default HTTPS port (443)' do
          expect(configuration.port).to eq(443)
        end
      end

      context 'with HTTP scheme' do
        let(:uri) { URI('http://example.com') }

        subject(:configuration) { described_class.new(uri) }

        it 'returns the default HTTP port (80)' do
          expect(configuration.port).to eq(80)
        end
      end
    end

    context 'when URI has explicit default ports' do
      context 'with HTTPS and explicit port 443' do
        let(:uri) { URI('https://example.com:443') }

        subject(:configuration) { described_class.new(uri) }

        it 'returns the explicit default port' do
          expect(configuration.port).to eq(443)
        end
      end

      context 'with HTTP and explicit port 80' do
        let(:uri) { URI('http://example.com:80') }

        subject(:configuration) { described_class.new(uri) }

        it 'returns the explicit default port' do
          expect(configuration.port).to eq(80)
        end
      end
    end

    context 'with cross-scheme port scenarios' do
      context 'with HTTPS using HTTP default port' do
        let(:uri) { URI('https://example.com:80') }

        subject(:configuration) { described_class.new(uri) }

        it 'returns port 80 (non-default for HTTPS)' do
          expect(configuration.port).to eq(80)
        end
      end

      context 'with HTTP using HTTPS default port' do
        let(:uri) { URI('http://example.com:443') }

        subject(:configuration) { described_class.new(uri) }

        it 'returns port 443 (non-default for HTTP)' do
          expect(configuration.port).to eq(443)
        end
      end
    end
  end

  describe '#protocol' do
    let(:uri) { URI('https://example.com') }

    subject(:configuration) { described_class.new(uri) }

    it 'returns the scheme from URI' do
      expect(configuration.protocol).to eq('https')
    end
  end
end
