# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::LetsEncrypt::Order do
  include LetsEncryptHelpers

  let(:acme_order) { acme_order_double }

  let(:order) { described_class.new(acme_order) }

  LetsEncryptHelpers::ACME_ORDER_METHODS.each do |method, value|
    describe "##{method}" do
      it 'delegates to Acme::Client::Resources::Order' do
        expect(order.public_send(method)).to eq(value)
      end
    end
  end

  describe '#new_challenge' do
    it 'returns challenge' do
      expect(order.new_challenge).to be_a(::Gitlab::LetsEncrypt::Challenge)
    end
  end

  describe '#request_certificate' do
    let(:private_key) do
      OpenSSL::PKey::RSA.new(4096).to_pem
    end

    it 'generates csr and finalizes order' do
      expect(acme_order).to receive(:finalize) do |csr:|
        expect do
          csr.csr # it's being evaluated lazily
        end.not_to raise_error
      end

      order.request_certificate(domain: 'example.com', private_key: private_key)
    end
  end

  describe '#challenge_error' do
    it 'returns error if challenge has errors' do
      challenge = acme_challenge_double

      # error just to give an example
      error = {
        "type" => "urn:ietf:params:acme:error:dns",
        "detail" => "No valid IP addresses found for test.example.com",
        "status" => 400
      }

      allow(challenge).to receive(:error).and_return(error)

      acme_order = acme_order_double(authorizations: [acme_authorization_double(challenge)])

      expect(described_class.new(acme_order).challenge_error).to eq(error)
    end
  end
end
