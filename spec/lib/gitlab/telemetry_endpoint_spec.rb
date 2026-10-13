# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::TelemetryEndpoint, feature_category: :service_ping do
  describe '.default_url' do
    subject(:default_url) { described_class.default_url }

    it 'is the staging Versions Application outside production' do
      expect(default_url).to eq(described_class::STAGING_URL)
    end

    context 'when running in production' do
      before do
        stub_rails_env('production')
      end

      it { is_expected.to eq(described_class::PRODUCTION_URL) }
    end
  end

  describe '.service_ping_url' do
    subject(:service_ping_url) { described_class.service_ping_url }

    context 'when GITLAB_SERVICE_PING_URL is not set' do
      it { is_expected.to eq(described_class::STAGING_URL) }

      context 'when running in production' do
        before do
          stub_rails_env('production')
        end

        it { is_expected.to eq(described_class::PRODUCTION_URL) }
      end
    end

    context 'when GITLAB_SERVICE_PING_URL is set' do
      before do
        stub_env(described_class::SERVICE_PING_ENV_VAR, value)
      end

      context 'with a bare origin' do
        let(:value) { 'http://localhost:3000' }

        it { is_expected.to eq('http://localhost:3000') }

        context 'when running in production' do
          before do
            stub_rails_env('production')
          end

          it { is_expected.to eq('http://localhost:3000') }
        end

        context 'when the licence forces Service Ping on' do
          before do
            allow(ServicePing::ServicePingSettings).to receive(:license_operational_metric_enabled?).and_return(true)
          end

          # Outside production the default is staging, which does not satisfy
          # the licence either, so refusing the override would achieve nothing.
          it { is_expected.to eq('http://localhost:3000') }

          context 'when running in production' do
            before do
              stub_rails_env('production')
            end

            it { is_expected.to eq(described_class::PRODUCTION_URL) }
          end
        end

        it 'does not read the licence outside production' do
          expect(ServicePing::ServicePingSettings).not_to receive(:license_operational_metric_enabled?)

          expect(service_ping_url).to eq('http://localhost:3000')
        end
      end

      context 'with a trailing slash' do
        let(:value) { 'https://version.example.com/' }

        it 'strips the trailing slash' do
          expect(service_ping_url).to eq('https://version.example.com')
        end
      end

      context 'when blank' do
        let(:value) { ' ' }

        it { is_expected.to eq(described_class::STAGING_URL) }
      end

      context 'with an invalid value' do
        where(:value) do
          [
            'http://localhost:3000/version',
            'http://localhost:3000?foo=bar',
            'http://localhost:3000#frag',
            'ftp://localhost:3000',
            'localhost:3000',
            'http://exa mple.com'
          ]
        end

        with_them do
          it 'falls back to the default destination without raising' do
            expect { service_ping_url }.not_to raise_error
            expect(service_ping_url).to eq(described_class::STAGING_URL)
          end
        end
      end
    end

    it 'is unaffected by GITLAB_VERSION_CHECK_URL' do
      stub_env(described_class::VERSION_CHECK_ENV_VAR, 'http://localhost:4000')

      expect(service_ping_url).to eq(described_class::STAGING_URL)
    end
  end

  describe '.version_check_url' do
    subject(:version_check_url) { described_class.version_check_url }

    context 'when GITLAB_VERSION_CHECK_URL is not set' do
      it { is_expected.to eq(described_class::STAGING_URL) }

      context 'when running in production' do
        before do
          stub_rails_env('production')
        end

        it { is_expected.to eq(described_class::PRODUCTION_URL) }
      end
    end

    context 'when GITLAB_VERSION_CHECK_URL is set' do
      before do
        stub_env(described_class::VERSION_CHECK_ENV_VAR, 'http://localhost:3000')
      end

      it { is_expected.to eq('http://localhost:3000') }

      # Unlike Service Ping, which a licence can oblige an instance to send.
      context 'when the licence forces Service Ping on' do
        before do
          allow(ServicePing::ServicePingSettings).to receive(:license_operational_metric_enabled?).and_return(true)
        end

        it { is_expected.to eq('http://localhost:3000') }
      end

      it 'does not consult the licence' do
        expect(ServicePing::ServicePingSettings).not_to receive(:license_operational_metric_enabled?)

        expect(version_check_url).to eq('http://localhost:3000')
      end
    end

    context 'when GITLAB_VERSION_CHECK_URL is invalid' do
      before do
        stub_env(described_class::VERSION_CHECK_ENV_VAR, 'http://localhost:3000/version')
      end

      it { is_expected.to eq(described_class::STAGING_URL) }
    end

    it 'is unaffected by GITLAB_SERVICE_PING_URL' do
      stub_env(described_class::SERVICE_PING_ENV_VAR, 'http://localhost:4000')

      expect(version_check_url).to eq(described_class::STAGING_URL)
    end
  end

  describe '.log_configuration' do
    subject(:log_configuration) { described_class.log_configuration }

    context 'when neither variable is set' do
      it 'logs nothing' do
        expect(Gitlab::AppLogger).not_to receive(:warn)
        expect(Gitlab::AppLogger).not_to receive(:error)

        log_configuration
      end
    end

    context 'when GITLAB_VERSION_CHECK_URL is set' do
      before do
        stub_env(described_class::VERSION_CHECK_ENV_VAR, 'http://localhost:3000')
      end

      it 'warns with the destination' do
        expect(Gitlab::AppLogger).to receive(:warn).with(
          message: a_string_including('is set to http://localhost:3000') &
            a_string_including('the version check is sent there') &
            a_string_including("instead of #{described_class::STAGING_URL}"),
          telemetry_endpoint_env_var: described_class::VERSION_CHECK_ENV_VAR,
          telemetry_endpoint_url: 'http://localhost:3000'
        )

        log_configuration
      end
    end

    context 'when GITLAB_SERVICE_PING_URL is valid' do
      before do
        stub_env(described_class::SERVICE_PING_ENV_VAR, 'http://localhost:3000/')
      end

      it 'warns with the destination, unhedged outside production' do
        expect(Gitlab::AppLogger).to receive(:warn).with(
          message: a_string_including('is set to http://localhost:3000') &
            a_string_including('Service Ping is sent there') &
            a_string_including("instead of #{described_class::STAGING_URL}"),
          telemetry_endpoint_env_var: described_class::SERVICE_PING_ENV_VAR,
          telemetry_endpoint_url: 'http://localhost:3000'
        )

        log_configuration
      end

      # The licence may refuse the override here, and this runs from an
      # initializer, which cannot read it.
      context 'when running in production' do
        before do
          stub_rails_env('production')
        end

        it 'hedges the warning' do
          expect(Gitlab::AppLogger).to receive(:warn).with(
            message: a_string_including('Service Ping may be sent there, unless the licence requires it'),
            telemetry_endpoint_env_var: described_class::SERVICE_PING_ENV_VAR,
            telemetry_endpoint_url: 'http://localhost:3000'
          )

          log_configuration
        end
      end

      it 'does not consult the licence' do
        expect(ServicePing::ServicePingSettings).not_to receive(:license_operational_metric_enabled?)

        log_configuration
      end
    end

    context 'when GITLAB_SERVICE_PING_URL is invalid' do
      before do
        stub_env(described_class::SERVICE_PING_ENV_VAR, 'http://localhost:3000/version')
      end

      it 'logs an error and does not raise' do
        expect(Gitlab::AppLogger).to receive(:error).with(
          message: a_string_including("#{described_class::SERVICE_PING_ENV_VAR} is ignored"),
          telemetry_endpoint_env_var: described_class::SERVICE_PING_ENV_VAR,
          telemetry_endpoint_url: 'http://localhost:3000/version'
        )

        expect { log_configuration }.not_to raise_error
      end
    end
  end
end
