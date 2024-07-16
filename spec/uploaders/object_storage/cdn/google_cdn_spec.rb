# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ObjectStorage::CDN::GoogleCDN,
  :use_clean_rails_memory_store_caching,
  :use_clean_rails_redis_caching,
  :sidekiq_inline,
  feature_category: :job_artifacts do # the google cdn is currently only used by build artifacts
  include StubRequests

  let(:key) { SecureRandom.hex }
  let(:key_name) { 'test-key' }
  let(:options) { { url: 'https://cdn.gitlab.example.com', key_name: key_name, key: Base64.urlsafe_encode64(key) } }
  let(:google_cloud_ips) { File.read(Rails.root.join('spec/fixtures/cdn/google_cloud.json')) }
  let(:headers) { { 'Content-Type' => 'application/json' } }
  let(:public_ip) { '18.245.0.42' }

  subject { described_class.new(options) }

  before do
    WebMock.stub_request(:get, CloudSeed::GoogleCloud::FetchGoogleIpListService::GOOGLE_IP_RANGES_URL)
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
      '127.0.0.1'                               | false
      '169.254.0.0'                             | false
    end

    with_them do
      it { expect(subject.use_cdn?(ip_address)).to eq(expected) }
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

    context 'when URL is a domain' do
      before do
        options[:url] = 'cdn.gitlab.example.com'
      end

      it 'returns false' do
        expect(subject.use_cdn?(public_ip)).to be false
      end
    end

    context 'when URL uses HTTP' do
      before do
        options[:url] = 'http://cdn.gitlab.example.com'
      end

      it 'returns false' do
        expect(subject.use_cdn?(public_ip)).to be false
      end
    end
  end

  describe '#signed_url', :freeze_time do
    let(:path) { '/path/to/file.txt' }
    let(:expiration) { (Time.current + 10.minutes).utc.to_i }
    let(:cdn_query_params) { "Expires=#{expiration}&KeyName=#{key_name}" }
    let(:encoded_path) { Addressable::URI.encode_component(path, Addressable::URI::CharacterClasses::PATH) }

    def verify_signature(url, unsigned_url)
      expect(url).to start_with("#{options[:url]}#{encoded_path}")

      uri = Addressable::URI.parse(url)
      query = uri.query_values
      signature = query['Signature']

      computed_signature = OpenSSL::HMAC.digest('SHA1', key, unsigned_url)

      aggregate_failures do
        expect(query['Expires'].to_i).to be > 0
        expect(query['KeyName']).to eq(key_name)
        expect(signature).to eq(Base64.urlsafe_encode64(computed_signature))
      end
    end

    context 'with UTF-8 characters in path' do
      let(:path) { "/path/to/©️job🧪" }
      let(:url) { subject.signed_url(path) }
      let(:unsigned_url) { "#{options[:url]}#{encoded_path}?#{cdn_query_params}" }

      it 'returns a valid signed URL' do
        verify_signature(url, unsigned_url)
      end
    end

    context 'with default query parameters' do
      let(:url) { subject.signed_url(path) }
      let(:unsigned_url) { "#{options[:url]}#{path}?#{cdn_query_params}" }

      it 'returns a valid signed URL' do
        verify_signature(url, unsigned_url)
      end
    end

    context 'with nil query parameters' do
      let(:url) { subject.signed_url(path, params: nil) }
      let(:unsigned_url) { "#{options[:url]}#{path}?#{cdn_query_params}" }

      it 'returns a valid signed URL' do
        verify_signature(url, unsigned_url)
      end
    end

    context 'with extra query parameters' do
      let(:url) { subject.signed_url(path, params: { 'response-content-type' => 'text/plain' }) }
      let(:unsigned_url) { "#{options[:url]}#{path}?response-content-type=text%2Fplain&#{cdn_query_params}" }

      it 'returns a valid signed URL' do
        verify_signature(url, unsigned_url)
      end
    end
  end
end
