# frozen_string_literal: true

require 'rails_helper'

describe Doorkeeper::OpenidConnect::OAuth::PasswordAccessTokenRequest do
  if Gem.loaded_specs['doorkeeper'].version >= Gem::Version.create('5.5.1')
    subject { Doorkeeper::OAuth::PasswordAccessTokenRequest.new server, client, credentials, resource_owner, { nonce: '123456' } }
  else
    subject { Doorkeeper::OAuth::PasswordAccessTokenRequest.new server, client, resource_owner, { nonce: '123456' } }
  end

  let(:server) { double }
  let(:client) { double }
  let(:credentials) { }
  let(:resource_owner) { create :user }
  let(:token) { create :access_token }
  let(:response) { Doorkeeper::OAuth::TokenResponse.new token }

  describe '#initialize' do
    it 'stores the nonce attribute' do
      expect(subject.nonce).to eq '123456'
    end
  end

  describe '#after_successful_response' do
    it 'adds the ID token to the response' do
      subject.instance_variable_set '@response', response
      subject.instance_variable_set '@access_token', token
      subject.send :after_successful_response

      expect(response.id_token).to be_a Doorkeeper::OpenidConnect::IdToken
      expect(response.id_token.nonce).to eq '123456'
    end
  end
end
