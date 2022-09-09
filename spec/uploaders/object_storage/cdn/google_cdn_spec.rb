# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ObjectStorage::CDN::GoogleCDN, :use_clean_rails_memory_store_caching do
  include StubRequests

  let(:key) { SecureRandom.hex }
  let(:key_name) { 'test-key' }
  let(:options) { { url: 'https://cdn.gitlab.example.com', key_name: key_name, key: Base64.urlsafe_encode64(key) } }
  let(:google_cloud_ips) { File.read(Rails.root.join('spec/fixtures/cdn/google_cloud.json')) }
  let(:headers) { { 'Content-Type' => 'application/json' } }
  let(:public_ip) { '18.245.0.42' }

  subject { described_class.new(options) }

  before do
    WebMock.stub_request(:get, described_class::GOOGLE_IP_RANGES_URL)
      .to_return(status: 200, body: google_cloud_ips, headers: headers)
  end

  describe '#use_cdn?' do
    using RSpec::Parameterized::TableSyntax

    where(:ip_address, :expected) do
      '34.80.0.1'                               | false
      '18.245.0.42'                             | true
      '2500:1900:4180:0000:0000:0000:0000:0000' | true
      '2600:1900:4180:0000:0000:0000:0000:0000' | false
      '10.10.1.5'                               | false
      'fc00:0000:0000:0000:0000:0000:0000:0000' | false
    end

    with_them do
      it { expect(subject.use_cdn?(ip_address)).to eq(expected) }
    end

    it 'caches the value' do
      expect(subject.use_cdn?(public_ip)).to be true
      expect(Rails.cache.fetch(described_class::GOOGLE_CDN_LIST_KEY)).to be_present
      expect(Gitlab::ProcessMemoryCache.cache_backend.fetch(described_class::GOOGLE_CDN_LIST_KEY)).to be_present
    end

    context 'when the key name is missing' do
      let(:options) { { url: 'https://cdn.gitlab.example.com', key: Base64.urlsafe_encode64(SecureRandom.hex) } }

      it 'returns false' do
        expect(subject.use_cdn?(public_ip)).to be false
      end
    end

    context 'when the key is missing' do
      let(:options) { { url: 'https://invalid.example.com' } }

      it 'returns false' do
        expect(subject.use_cdn?(public_ip)).to be false
      end
    end

    context 'when the key is invalid' do
      let(:options) { { key_name: key_name, key: '\0x1' } }

      it 'returns false' do
        expect(Gitlab::ErrorTracking).to receive(:log_exception).and_call_original
        expect(subject.use_cdn?(public_ip)).to be false
      end
    end

    context 'when the URL is missing' do
      let(:options) { { key: Base64.urlsafe_encode64(SecureRandom.hex) } }

      it 'returns false' do
        expect(subject.use_cdn?(public_ip)).to be false
      end
    end

    shared_examples 'IP range retrieval failure' do
      it 'does not cache the result and logs an error' do
        expect(Gitlab::ErrorTracking).to receive(:log_exception).and_call_original
        expect(subject.use_cdn?(public_ip)).to be false
        expect(Rails.cache.fetch(described_class::GOOGLE_CDN_LIST_KEY)).to be_nil
        expect(Gitlab::ProcessMemoryCache.cache_backend.fetch(described_class::GOOGLE_CDN_LIST_KEY)).to be_nil
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

  describe '#signed_url' do
    let(:path) { '/path/to/file.txt' }

    it 'returns a valid signed URL' do
      url = subject.signed_url(path)

      expect(url).to start_with("#{options[:url]}#{path}")

      uri = Addressable::URI.parse(url)
      parsed_query = Rack::Utils.parse_nested_query(uri.query)
      signature = parsed_query.delete('Signature')

      signed_url = "#{options[:url]}#{path}?Expires=#{parsed_query['Expires']}&KeyName=#{key_name}"
      computed_signature = OpenSSL::HMAC.digest('SHA1', key, signed_url)

      aggregate_failures do
        expect(parsed_query['Expires'].to_i).to be > 0
        expect(parsed_query['KeyName']).to eq(key_name)
        expect(signature).to eq(Base64.urlsafe_encode64(computed_signature))
      end
    end
  end
end
