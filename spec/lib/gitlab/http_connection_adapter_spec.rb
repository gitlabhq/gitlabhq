# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::HTTPConnectionAdapter do
  describe '#connection' do
    context 'when local requests are not allowed' do
      it 'sets up the connection' do
        uri = URI('https://example.org')

        connection = described_class.new(uri).connection

        expect(connection).to be_a(Net::HTTP)
        expect(connection.address).to eq('93.184.216.34')
        expect(connection.hostname_override).to eq('example.org')
        expect(connection.addr_port).to eq('example.org')
        expect(connection.port).to eq(443)
      end

      it 'raises error when it is a request to local address' do
        uri = URI('http://172.16.0.0/12')

        expect { described_class.new(uri).connection }
          .to raise_error(Gitlab::HTTP::BlockedUrlError,
                          "URL 'http://172.16.0.0/12' is blocked: Requests to the local network are not allowed")
      end

      it 'raises error when it is a request to localhost address' do
        uri = URI('http://127.0.0.1')

        expect { described_class.new(uri).connection }
          .to raise_error(Gitlab::HTTP::BlockedUrlError,
                          "URL 'http://127.0.0.1' is blocked: Requests to localhost are not allowed")
      end

      context 'when port different from URL scheme is used' do
        it 'sets up the addr_port accordingly' do
          uri = URI('https://example.org:8080')

          connection = described_class.new(uri).connection

          expect(connection.address).to eq('93.184.216.34')
          expect(connection.hostname_override).to eq('example.org')
          expect(connection.addr_port).to eq('example.org:8080')
          expect(connection.port).to eq(8080)
        end
      end
    end

    context 'when DNS rebinding protection is disabled' do
      it 'sets up the connection' do
        stub_application_setting(dns_rebinding_protection_enabled: false)

        uri = URI('https://example.org')

        connection = described_class.new(uri).connection

        expect(connection).to be_a(Net::HTTP)
        expect(connection.address).to eq('example.org')
        expect(connection.hostname_override).to eq(nil)
        expect(connection.addr_port).to eq('example.org')
        expect(connection.port).to eq(443)
      end
    end

    context 'when http(s) environment variable is set' do
      it 'sets up the connection' do
        stub_env('https_proxy' => 'https://my.proxy')

        uri = URI('https://example.org')

        connection = described_class.new(uri).connection

        expect(connection).to be_a(Net::HTTP)
        expect(connection.address).to eq('example.org')
        expect(connection.hostname_override).to eq(nil)
        expect(connection.addr_port).to eq('example.org')
        expect(connection.port).to eq(443)
      end
    end

    context 'when local requests are allowed' do
      it 'sets up the connection' do
        uri = URI('https://example.org')

        connection = described_class.new(uri, allow_local_requests: true).connection

        expect(connection).to be_a(Net::HTTP)
        expect(connection.address).to eq('93.184.216.34')
        expect(connection.hostname_override).to eq('example.org')
        expect(connection.addr_port).to eq('example.org')
        expect(connection.port).to eq(443)
      end

      it 'sets up the connection when it is a local network' do
        uri = URI('http://172.16.0.0/12')

        connection = described_class.new(uri, allow_local_requests: true).connection

        expect(connection).to be_a(Net::HTTP)
        expect(connection.address).to eq('172.16.0.0')
        expect(connection.hostname_override).to be(nil)
        expect(connection.addr_port).to eq('172.16.0.0')
        expect(connection.port).to eq(80)
      end

      it 'sets up the connection when it is localhost' do
        uri = URI('http://127.0.0.1')

        connection = described_class.new(uri, allow_local_requests: true).connection

        expect(connection).to be_a(Net::HTTP)
        expect(connection.address).to eq('127.0.0.1')
        expect(connection.hostname_override).to be(nil)
        expect(connection.addr_port).to eq('127.0.0.1')
        expect(connection.port).to eq(80)
      end
    end
  end
end
