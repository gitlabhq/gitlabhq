# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Version::VersionCheckCronWorker, feature_category: :service_ping do
  let(:worker) { described_class.new }
  let(:response) { double }
  let(:version_info) { { 'version' => '1.0.0' } }
  let(:encoded_data) { Base64.urlsafe_encode64({ version: Gitlab::VERSION }.to_json) }
  let(:check_path) { "/check.json?gitlab_info=#{encoded_data}" }
  let(:production_url) { "#{Gitlab::TelemetryEndpoint::PRODUCTION_URL}#{check_path}" }

  # The test environment is not production, so the default destination is staging.
  let(:version_url) { "#{Gitlab::TelemetryEndpoint::STAGING_URL}#{check_path}" }

  # A redirected destination is typically local, so the request must be allowed to
  # reach one. Asserted on every stub below: dropping it breaks this whole file.
  let(:http_options) { { allow_local_requests: true } }

  before do
    allow(Gitlab::HTTP).to receive(:try_get).with(version_url, http_options).and_return(response)
  end

  describe '#perform' do
    describe 'destination host' do
      before do
        allow(response).to receive_messages(body: version_info.to_json, code: 200)
      end

      it 'requests the staging Versions Application outside production' do
        expect(Gitlab::HTTP).to receive(:try_get).with(version_url, http_options).and_return(response)
        expect(Gitlab::HTTP).not_to receive(:try_get).with(production_url, http_options)

        worker.perform
      end

      context 'when running in production' do
        before do
          stub_rails_env('production')
        end

        it 'requests version.gitlab.com' do
          expect(Gitlab::HTTP).to receive(:try_get).with(production_url, http_options).and_return(response)
          expect(Gitlab::HTTP).not_to receive(:try_get).with(version_url, http_options)

          worker.perform
        end
      end

      # Gitlab::TelemetryEndpoint resolves the destination and is specced
      # separately; this only proves the worker requests whatever it returns.
      context 'when the destination is overridden' do
        let(:destination) { 'http://localhost:3000' }

        it 'requests Gitlab::TelemetryEndpoint.version_check_url' do
          allow(Gitlab::TelemetryEndpoint).to receive(:version_check_url).and_return(destination)

          expect(Gitlab::HTTP).to receive(:try_get).with("#{destination}#{check_path}",
            http_options).and_return(response)
          expect(Gitlab::HTTP).not_to receive(:try_get).with(version_url, http_options)

          worker.perform
        end
      end
    end

    context 'when request is successful' do
      before do
        allow(response).to receive_messages(body: version_info.to_json, code: 200)
      end

      it 'caches the version information' do
        expect(Rails.cache).to receive(:write).with('version_check', version_info)

        worker.perform
      end

      it 'logs the response' do
        expect(Gitlab::AppLogger).to receive(:info).with(
          message: 'Version check succeeded',
          result: version_info)

        worker.perform
      end
    end

    context 'when request fails' do
      before do
        allow(response).to receive_messages(body: 'error', code: 500)
      end

      it 'logs an error' do
        expect(Gitlab::AppLogger).to receive(:error).with(
          message: 'Version check failed',
          error: { code: 500, message: 'error' }
        )

        worker.perform
      end
    end

    context 'when response is not present' do
      before do
        allow(Gitlab::HTTP).to receive(:try_get).with(version_url, http_options).and_return(nil)
      end

      it 'logs an error' do
        expect(Gitlab::AppLogger).to receive(:error).with(
          message: 'Version check failed',
          error: { code: nil, message: nil }
        )

        worker.perform
      end
    end

    context 'when JSON parsing fails' do
      before do
        allow(response).to receive_messages(body: 'invalid json', code: 200)
      end

      it 'logs a parsing error' do
        expect(Gitlab::AppLogger).to receive(:error).with(
          message: 'Parsing version check response failed',
          error: { message: kind_of(String), code: 200 }
        )

        worker.perform
      end
    end
  end
end
