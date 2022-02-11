# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::HTTPConnectionAdapter do
  include StubRequests

  let(:uri) { URI('https://example.org') }
  let(:options) { {} }

  subject(:connection) { described_class.new(uri, options).connection }

  describe '#connection' do
    before do
      stub_all_dns('https://example.org', ip_address: '93.184.216.34')
    end

    context 'with use_read_total_timeout option' do
      let(:options) { { use_read_total_timeout: true } }

      it 'sets up the connection using the Gitlab::NetHttpAdapter' do
        expect(connection).to be_a(Gitlab::NetHttpAdapter)
        expect(connection.address).to eq('93.184.216.34')
        expect(connection.hostname_override).to eq('example.org')
        expect(connection.addr_port).to eq('example.org')
        expect(connection.port).to eq(443)
      end
    end

    context 'with header_read_timeout_buffered_io feature disabled' do
      before do
        stub_feature_flags(header_read_timeout_buffered_io: false)
      end

      it 'uses the regular Net::HTTP class' do
        expect(connection).to be_a(Net::HTTP)
      end
    end

    context 'when local requests are allowed' do
      let(:options) { { allow_local_requests: true } }

      it 'sets up the connection' do
        expect(connection).to be_a(Gitlab::NetHttpAdapter)
        expect(connection.address).to eq('93.184.216.34')
        expect(connection.hostname_override).to eq('example.org')
        expect(connection.addr_port).to eq('example.org')
        expect(connection.port).to eq(443)
      end
    end

    context 'when local requests are not allowed' do
      let(:options) { { allow_local_requests: false } }

      it 'sets up the connection' do
        expect(connection).to be_a(Gitlab::NetHttpAdapter)
        expect(connection.address).to eq('93.184.216.34')
        expect(connection.hostname_override).to eq('example.org')
        expect(connection.addr_port).to eq('example.org')
        expect(connection.port).to eq(443)
      end

      context 'when it is a request to local network' do
        let(:uri) { URI('http://172.16.0.0/12') }

        it 'raises error' do
          expect { subject }.to raise_error(
            Gitlab::HTTP::BlockedUrlError,
            "URL 'http://172.16.0.0/12' is blocked: Requests to the local network are not allowed"
          )
        end

        context 'when local request allowed' do
          let(:options) { { allow_local_requests: true } }

          it 'sets up the connection' do
            expect(connection).to be_a(Gitlab::NetHttpAdapter)
            expect(connection.address).to eq('172.16.0.0')
            expect(connection.hostname_override).to be(nil)
            expect(connection.addr_port).to eq('172.16.0.0')
            expect(connection.port).to eq(80)
          end
        end
      end

      context 'when it is a request to local address' do
        let(:uri) { URI('http://127.0.0.1') }

        it 'raises error' do
          expect { subject }.to raise_error(
            Gitlab::HTTP::BlockedUrlError,
            "URL 'http://127.0.0.1' is blocked: Requests to localhost are not allowed"
          )
        end

        context 'when local request allowed' do
          let(:options) { { allow_local_requests: true } }

          it 'sets up the connection' do
            expect(connection).to be_a(Gitlab::NetHttpAdapter)
            expect(connection.address).to eq('127.0.0.1')
            expect(connection.hostname_override).to be(nil)
            expect(connection.addr_port).to eq('127.0.0.1')
            expect(connection.port).to eq(80)
          end
        end
      end

      context 'when port different from URL scheme is used' do
        let(:uri) { URI('https://example.org:8080') }

        it 'sets up the addr_port accordingly' do
          expect(connection).to be_a(Gitlab::NetHttpAdapter)
          expect(connection.address).to eq('93.184.216.34')
          expect(connection.hostname_override).to eq('example.org')
          expect(connection.addr_port).to eq('example.org:8080')
          expect(connection.port).to eq(8080)
        end
      end
    end

    context 'when DNS rebinding protection is disabled' do
      before do
        stub_application_setting(dns_rebinding_protection_enabled: false)
      end

      it 'sets up the connection' do
        expect(connection).to be_a(Gitlab::NetHttpAdapter)
        expect(connection.address).to eq('example.org')
        expect(connection.hostname_override).to eq(nil)
        expect(connection.addr_port).to eq('example.org')
        expect(connection.port).to eq(443)
      end
    end

    context 'when http(s) environment variable is set' do
      before do
        stub_env('https_proxy' => 'https://my.proxy')
      end

      it 'sets up the connection' do
        expect(connection).to be_a(Gitlab::NetHttpAdapter)
        expect(connection.address).to eq('example.org')
        expect(connection.hostname_override).to eq(nil)
        expect(connection.addr_port).to eq('example.org')
        expect(connection.port).to eq(443)
      end
    end
  end
end
