# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Logging::CloudflareHelper do
  let(:helper) do
    Class.new do
      include Gitlab::Logging::CloudflareHelper
    end.new
  end

  describe '#store_cloudflare_headers!' do
    let(:payload) { {} }
    let(:env) { {} }
    let(:request) { ActionDispatch::Request.new(env) }

    before do
      request.headers.merge!(headers)
    end

    context 'with normal headers' do
      let(:headers) do
        {
          'Cf-Ray' => '592f0aa22b3dea38-IAD',
          'Cf-Request-Id' => SecureRandom.hex,
          'Cf-IPCountry' => 'US',
          'Cf-Worker' => 'subdomain.domain.com'
        }
      end

      it 'adds Cf-Ray-Id and Cf-Request-Id' do
        helper.store_cloudflare_headers!(payload, request)

        expect(payload[:cf_ray]).to eq(headers['Cf-Ray'])
        expect(payload[:cf_request_id]).to eq(headers['Cf-Request-Id'])
        expect(payload[:cf_ipcountry]).to eq(headers['Cf-IPCountry'])
        expect(payload[:cf_worker]).to eq(headers['Cf-Worker'])
      end
    end

    context 'with header values with long strings' do
      let(:headers) { { 'Cf-Ray' => SecureRandom.hex(33), 'Cf-Request-Id' => SecureRandom.hex(33) } }

      it 'filters invalid header values' do
        helper.store_cloudflare_headers!(payload, request)

        expect(payload.keys).not_to include(:cf_ray, :cf_request_id)
      end
    end

    context 'with header values with non-alphanumeric characters' do
      let(:headers) { { 'Cf-Ray' => "Bad\u0000ray", 'Cf-Request-Id' => "Bad\u0000req" } }

      it 'filters invalid header values' do
        helper.store_cloudflare_headers!(payload, request)

        expect(payload.keys).not_to include(:cf_ray, :cf_request_id)
      end
    end
  end
end
