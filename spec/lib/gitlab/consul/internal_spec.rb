# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Consul::Internal do
  let(:api_url) { 'http://127.0.0.1:8500' }

  let(:consul_settings) do
    {
      api_url: api_url
    }
  end

  before do
    stub_config(consul: consul_settings)
  end

  describe '.api_url' do
    it 'returns correct value' do
      expect(described_class.api_url).to eq(api_url)
    end

    context 'when consul setting is not present in gitlab.yml' do
      before do
        allow(Gitlab.config).to receive(:consul).and_raise(Settingslogic::MissingSetting)
      end

      it 'does not fail' do
        expect(described_class.api_url).to be_nil
      end
    end
  end

  shared_examples 'handles failure response' do
    it 'raises Gitlab::Consul::Internal::SocketError when SocketError is rescued' do
      stub_consul_discover_prometheus.to_raise(::SocketError)

      expect { subject }
        .to raise_error(described_class::SocketError)
    end

    it 'raises Gitlab::Consul::Internal::SSLError when OpenSSL::SSL::SSLError is rescued' do
      stub_consul_discover_prometheus.to_raise(OpenSSL::SSL::SSLError)

      expect { subject }
        .to raise_error(described_class::SSLError)
    end

    it 'raises Gitlab::Consul::Internal::ECONNREFUSED when Errno::ECONNREFUSED is rescued' do
      stub_consul_discover_prometheus.to_raise(Errno::ECONNREFUSED)

      expect { subject }
        .to raise_error(described_class::ECONNREFUSED)
    end

    it 'raises Consul::Internal::UnexpectedResponseError when StandardError is rescued' do
      stub_consul_discover_prometheus.to_raise(StandardError)

      expect { subject }
        .to raise_error(described_class::UnexpectedResponseError)
    end

    it 'raises Consul::Internal::UnexpectedResponseError when request returns 500' do
      stub_consul_discover_prometheus.to_return(status: 500, body: '{ message: "FAIL!" }')

      expect { subject }
        .to raise_error(described_class::UnexpectedResponseError)
    end

    it 'raises Consul::Internal::UnexpectedResponseError when request returns non json data' do
      stub_consul_discover_prometheus.to_return(status: 200, body: 'not json')

      expect { subject }
        .to raise_error(described_class::UnexpectedResponseError)
    end
  end

  shared_examples 'returns nil given blank value of' do |input_symbol|
    [nil, ''].each do |value|
      let(input_symbol) { value }

      it { is_expected.to be_nil }
    end
  end

  describe '.discover_service' do
    subject { described_class.discover_service(service_name: service_name) }

    let(:service_name) { 'prometheus' }

    it_behaves_like 'returns nil given blank value of', :api_url

    it_behaves_like 'returns nil given blank value of', :service_name

    context 'one service discovered' do
      before do
        stub_consul_discover_prometheus.to_return(status: 200, body: '[{"ServiceAddress":"prom.net","ServicePort":9090}]')
      end

      it 'returns the service address and port' do
        is_expected.to eq(["prom.net", 9090])
      end
    end

    context 'multiple services discovered' do
      before do
        stub_consul_discover_prometheus
          .to_return(status: 200, body: '[{"ServiceAddress":"prom_1.net","ServicePort":9090},{"ServiceAddress":"prom.net","ServicePort":9090}]')
      end

      it 'uses the first service' do
        is_expected.to eq(["prom_1.net", 9090])
      end
    end

    it_behaves_like 'handles failure response'
  end

  describe '.discover_prometheus_server_address' do
    subject { described_class.discover_prometheus_server_address }

    before do
      stub_consul_discover_prometheus
        .to_return(status: 200, body: '[{"ServiceAddress":"prom.net","ServicePort":9090}]')
    end

    it 'returns the server address' do
      is_expected.to eq('prom.net:9090')
    end

    it_behaves_like 'returns nil given blank value of', :api_url

    it_behaves_like 'handles failure response'
  end

  def stub_consul_discover_prometheus
    stub_request(:get, %r{v1/catalog/service/prometheus})
  end
end
