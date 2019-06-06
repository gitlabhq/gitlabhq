# frozen_string_literal: true

require 'spec_helper'

describe ::Gitlab::LetsEncrypt::Challenge do
  include LetsEncryptHelpers

  let(:challenge) { described_class.new(acme_challenge_double) }

  LetsEncryptHelpers::ACME_CHALLENGE_METHODS.each do |method, value|
    describe "##{method}" do
      it 'delegates to Acme::Client::Resources::Challenge' do
        expect(challenge.public_send(method)).to eq(value)
      end
    end
  end
end
