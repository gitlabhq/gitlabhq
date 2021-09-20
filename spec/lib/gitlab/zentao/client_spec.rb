# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Zentao::Client do
  subject(:integration) { described_class.new(zentao_integration) }

  let(:zentao_integration) { create(:zentao_integration) }
  let(:mock_get_products_url) { integration.send(:url, "products/#{zentao_integration.zentao_product_xid}") }

  describe '#new' do
    context 'if integration is nil' do
      let(:zentao_integration) { nil }

      it 'raises ConfigError' do
        expect { integration }.to raise_error(described_class::ConfigError)
      end
    end

    context 'integration is provided' do
      it 'is initialized successfully' do
        expect { integration }.not_to raise_error
      end
    end
  end

  describe '#fetch_product' do
    let(:mock_headers) do
      {
        headers: {
          'Content-Type' => 'application/json',
          'Token' => zentao_integration.api_token
        }
      }
    end

    context 'with valid product' do
      let(:mock_response) { { 'id' => zentao_integration.zentao_product_xid } }

      before do
        WebMock.stub_request(:get, mock_get_products_url)
               .with(mock_headers).to_return(status: 200, body: mock_response.to_json)
      end

      it 'fetches the product' do
        expect(integration.fetch_product(zentao_integration.zentao_product_xid)).to eq mock_response
      end
    end

    context 'with invalid product' do
      before do
        WebMock.stub_request(:get, mock_get_products_url)
               .with(mock_headers).to_return(status: 404, body: {}.to_json)
      end

      it 'fetches the empty product' do
        expect(integration.fetch_product(zentao_integration.zentao_product_xid)).to eq({})
      end
    end

    context 'with invalid response' do
      before do
        WebMock.stub_request(:get, mock_get_products_url)
               .with(mock_headers).to_return(status: 200, body: '[invalid json}')
      end

      it 'fetches the empty product' do
        expect(integration.fetch_product(zentao_integration.zentao_product_xid)).to eq({})
      end
    end
  end

  describe '#ping' do
    let(:mock_headers) do
      {
        headers: {
          'Content-Type' => 'application/json',
          'Token' => zentao_integration.api_token
        }
      }
    end

    context 'with valid resource' do
      before do
        WebMock.stub_request(:get, mock_get_products_url)
               .with(mock_headers).to_return(status: 200, body: { 'deleted' => '0' }.to_json)
      end

      it 'responds with success' do
        expect(integration.ping[:success]).to eq true
      end
    end

    context 'with deleted resource' do
      before do
        WebMock.stub_request(:get, mock_get_products_url)
               .with(mock_headers).to_return(status: 200, body: { 'deleted' => '1' }.to_json)
      end

      it 'responds with unsuccess' do
        expect(integration.ping[:success]).to eq false
      end
    end
  end
end
