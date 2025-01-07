# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CloudSeed::GoogleCloud::FetchGoogleIpListService, :use_clean_rails_memory_store_caching,
  :clean_gitlab_redis_rate_limiting, feature_category: :job_artifacts do
  include StubRequests

  let(:google_cloud_ips) { File.read(Rails.root.join('spec/fixtures/cdn/google_cloud.json')) }
  let(:headers) { { 'Content-Type' => 'application/json' } }

  subject { described_class.new.execute }

  before do
    WebMock.stub_request(:get, described_class::GOOGLE_IP_RANGES_URL)
      .to_return(status: 200, body: google_cloud_ips, headers: headers)
  end

  describe '#execute' do
    it 'returns a list of IPAddr subnets and caches the result' do
      expect(::ObjectStorage::CDN::GoogleIpCache).to receive(:update!).and_call_original
      expect(subject[:subnets]).to be_an(Array)
      expect(subject[:subnets]).to all(be_an(IPAddr))
    end

    shared_examples 'IP range retrieval failure' do
      it 'does not cache the result and logs an error' do
        expect(Gitlab::ErrorTracking).to receive(:log_exception).and_call_original
        expect(::ObjectStorage::CDN::GoogleIpCache).not_to receive(:update!)
        expect(subject[:subnets]).to be_nil
      end
    end

    context 'with rate limit in effect' do
      before do
        allow(Gitlab::ApplicationRateLimiter).to receive(:throttled?).and_return(true)
      end

      it 'returns rate limit error' do
        expect(subject[:status]).to eq(:error)
        expect(subject[:message]).to eq("#{described_class} was rate limited")
      end
    end

    context 'when the URL returns a 404' do
      before do
        WebMock.stub_request(:get, described_class::GOOGLE_IP_RANGES_URL).to_return(status: 404)
      end

      it_behaves_like 'IP range retrieval failure'
    end

    context 'when the URL returns too large of a payload' do
      before do
        stub_const("#{described_class}::RESPONSE_BODY_LIMIT", 300)
      end

      it_behaves_like 'IP range retrieval failure'
    end

    context 'when the URL returns HTML' do
      let(:headers) { { 'Content-Type' => 'text/html' } }

      it_behaves_like 'IP range retrieval failure'
    end

    context 'when the URL returns empty results' do
      let(:google_cloud_ips) { '{}' }

      it_behaves_like 'IP range retrieval failure'
    end
  end
end
