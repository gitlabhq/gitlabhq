# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::LetsEncrypt::Order, feature_category: :pages do
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
    it { expect(order.new_challenge).to be_a ::Gitlab::LetsEncrypt::Challenge }
  end

  describe '#request_certificate' do
    let(:private_key) { OpenSSL::PKey::RSA.new(4096).to_pem }

    before do
      allow(acme_order).to receive(:finalize)
    end

    it 'generates csr and finalizes order' do
      order.request_certificate(domain: 'example.com', private_key: private_key)

      expect(acme_order).to have_received(:finalize) do |csr:|
        # it's being evaluated lazily
        expect { csr.csr }.not_to raise_error
      end
    end
  end

  describe '#challenge_error' do
    let(:acme_order) { acme_order_double(authorizations: [acme_authorization_double(challenge)]) }
    let(:challenge) { acme_challenge_double(error: expected_challenge_error) }
    let(:expected_challenge_error) do
      {
        "type" => "urn:ietf:params:acme:error:dns",
        "detail" => "No valid IP addresses found for test.example.com",
        "status" => 400
      }
    end

    subject(:challenge_order) { order.challenge_error }

    it { is_expected.to eq expected_challenge_error }

    context 'when requesting authorizations raises error' do
      let(:acme_order) { acme_order_double }

      before do
        allow(acme_order).to receive(:authorizations).and_raise(StandardError, 'ACME authorization error')
      end

      it { is_expected.to eq 'ACME authorization error' }
    end
  end
end
