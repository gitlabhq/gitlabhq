# frozen_string_literal: true

require 'spec_helper'

describe ::Gitlab::LetsEncrypt::Order do
  delegated_methods = {
    url: 'https://example.com/',
    status: 'valid'
  }

  let(:acme_order) do
    acme_order = instance_double('Acme::Client::Resources::Order')
    allow(acme_order).to receive_messages(delegated_methods)
    acme_order
  end

  let(:order) { described_class.new(acme_order) }

  delegated_methods.each do |method, value|
    describe "##{method}" do
      it 'delegates to Acme::Client::Resources::Order' do
        expect(order.public_send(method)).to eq(value)
      end
    end
  end

  describe '#new_challenge' do
    before do
      challenge = instance_double('Acme::Client::Resources::Challenges::HTTP01')
      authorization = instance_double('Acme::Client::Resources::Authorization')
      allow(authorization).to receive(:http).and_return(challenge)
      allow(acme_order).to receive(:authorizations).and_return([authorization])
    end

    it 'returns challenge' do
      expect(order.new_challenge).to be_a(::Gitlab::LetsEncrypt::Challenge)
    end
  end
end
