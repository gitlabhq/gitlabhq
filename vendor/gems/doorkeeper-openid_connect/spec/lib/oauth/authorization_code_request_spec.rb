# frozen_string_literal: true

require 'rails_helper'

describe Doorkeeper::OpenidConnect::OAuth::AuthorizationCodeRequest do
  subject do
    Doorkeeper::OAuth::AuthorizationCodeRequest.new(server, grant, client).tap do |request|
      request.instance_variable_set '@response', response
      request.instance_variable_set('@access_token', token)
    end
  end

  let(:server) { double }
  let(:client) { double }
  let(:grant) { create :access_grant, openid_request: openid_request }
  let(:openid_request) { create :openid_request, nonce: '123456' }
  let(:token) { create :access_token }
  let(:response) { Doorkeeper::OAuth::TokenResponse.new token }

  describe '#after_successful_response' do
    it 'adds the ID token to the response' do
      subject.send :after_successful_response

      expect(response.id_token).to be_a Doorkeeper::OpenidConnect::IdToken
      expect(response.id_token.nonce).to eq '123456'
    end

    it 'destroys the OpenID request record' do
      grant.save!

      expect do
        subject.send :after_successful_response
      end.to change { Doorkeeper::OpenidConnect::Request.count }.by(-1)
    end

    it 'skips the nonce if not present' do
      grant.openid_request.nonce = nil
      subject.send :after_successful_response

      expect(response.id_token.nonce).to be_nil
    end
  end
end
