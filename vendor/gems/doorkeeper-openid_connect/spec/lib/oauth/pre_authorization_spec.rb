# frozen_string_literal: true

require 'rails_helper'

describe Doorkeeper::OpenidConnect::OAuth::PreAuthorization do
  subject { Doorkeeper::OAuth::PreAuthorization.new server, attrs }

  let(:server) { Doorkeeper.configuration }
  let(:attrs) {}

  describe '#initialize' do
    context 'with nonce parameter' do
      let(:attrs) { { nonce: '123456' } }

      it 'stores the nonce attribute' do
        expect(subject.nonce).to eq '123456'
      end
    end
  end

  describe '#error_response' do
    context 'with response_type = code' do
      let(:attrs) { { response_type: 'code', redirect_uri: 'client.com/callback' } }

      it 'redirects to redirect_uri with query parameter' do
        expect(subject.error_response.redirect_uri).to match(/#{attrs[:redirect_uri]}\?/)
      end
    end

    context 'with response_type = token' do
      let(:attrs) { { response_type: 'token', redirect_uri: 'client.com/callback' } }

      it 'redirects to redirect_uri with fragment' do
        expect(subject.error_response.redirect_uri).to match(/#{attrs[:redirect_uri]}#/)
      end
    end

    context 'with response_type = id_token' do
      let(:attrs) { { response_type: 'id_token', redirect_uri: 'client.com/callback' } }

      it 'redirects to redirect_uri with fragment' do
        expect(subject.error_response.redirect_uri).to match(/#{attrs[:redirect_uri]}#/)
      end
    end

    context 'with response_type = id_token token' do
      let(:attrs) { { response_type: 'id_token token', redirect_uri: 'client.com/callback' } }

      it 'redirects to redirect_uri with fragment' do
        expect(subject.error_response.redirect_uri).to match(/#{attrs[:redirect_uri]}#/)
      end
    end
  end
end
