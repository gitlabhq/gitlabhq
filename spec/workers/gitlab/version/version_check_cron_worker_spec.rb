# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Version::VersionCheckCronWorker, feature_category: :service_ping do
  let(:worker) { described_class.new }
  let(:response) { double }
  let(:version_info) { { 'version' => '1.0.0' } }
  let(:encoded_data) { Base64.urlsafe_encode64({ version: Gitlab::VERSION }.to_json) }
  let(:version_url) { "https://version.gitlab.com/check.json?gitlab_info=#{encoded_data}" }

  before do
    allow(Gitlab::HTTP).to receive(:try_get).with(version_url).and_return(response)
  end

  describe '#perform' do
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
        allow(Gitlab::HTTP).to receive(:try_get).with(version_url).and_return(nil)
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
