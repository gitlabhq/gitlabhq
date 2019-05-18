# frozen_string_literal: true

require 'spec_helper'

describe ::Gitlab::LetsEncrypt::Challenge do
  delegated_methods = {
    url: 'https://example.com/',
    status: 'pending',
    token: 'tokenvalue',
    file_content: 'hereisfilecontent',
    request_validation: true
  }

  let(:acme_challenge) do
    acme_challenge = instance_double('Acme::Client::Resources::Challenge')
    allow(acme_challenge).to receive_messages(delegated_methods)
    acme_challenge
  end

  let(:challenge) { described_class.new(acme_challenge) }

  delegated_methods.each do |method, value|
    describe "##{method}" do
      it 'delegates to Acme::Client::Resources::Challenge' do
        expect(challenge.public_send(method)).to eq(value)
      end
    end
  end
end
