# frozen_string_literal: true

require 'rails_helper'

describe Doorkeeper::OpenidConnect::OAuth::TokenResponse do
  subject { Doorkeeper::OAuth::TokenResponse.new token }

  let(:token) { create :access_token }
  let(:client) { Doorkeeper::OAuth::Client.new create(:application) }
  let(:pre_auth) { Doorkeeper::OAuth::PreAuthorization.new(Doorkeeper.configuration, client_id: client.uid, nonce: '123456') }
  let(:id_token) { Doorkeeper::OpenidConnect::IdToken.new token, pre_auth }

  before do
    pre_auth.valid? # triggers loading of pre_auth.client
  end

  describe '#body' do
    before do
      subject.id_token = id_token
    end

    context 'with the openid scope present' do
      before do
        token.scopes = 'openid email'
      end

      it 'adds the ID token to the response' do
        expect(subject.body[:id_token]).to eq id_token.as_jws_token
      end
    end

    context 'with the openid scope present but no id_token' do
      before do
        token.scopes = 'openid email'
        subject.id_token = nil
      end

      it 'adds the ID token to the response' do
        expect(subject.body[:id_token]).to be_truthy
      end
    end

    context 'with the openid scope not present' do
      before do
        token.scopes = 'email'
      end

      it 'does not add the ID token to the response' do
        expect(subject.body).not_to include :id_token
      end
    end
  end
end
