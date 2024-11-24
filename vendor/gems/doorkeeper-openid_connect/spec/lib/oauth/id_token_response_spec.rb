# frozen_string_literal: true

require 'rails_helper'

describe Doorkeeper::OAuth::IdTokenResponse do
  subject { described_class.new(pre_auth, auth, id_token) }

  let(:token) { create :access_token }
  let(:application) do
    create(:application, scopes: 'public')
  end

  let(:pre_auth) do
    double(
      :pre_auth,
      client: application,
      redirect_uri: 'http://tst.com/cb',
      state: 'state',
      scopes: Doorkeeper::OAuth::Scopes.from_string('public'),
      error: nil,
      authorizable?: true,
      nonce: '12345'
    )
  end

  let(:owner) { build_stubbed(:user) }

  let(:auth) do
    Doorkeeper::OAuth::Authorization::Token.new(pre_auth, owner).tap do |c|
      if c.respond_to?(:issue_token!)
        c.issue_token!
      else
        c.issue_token
      end
    end
  end
  let(:id_token) { Doorkeeper::OpenidConnect::IdToken.new(token, pre_auth) }

  describe '#body' do
    it 'return body response for id_token' do
      expect(subject.body).to eq({
        expires_in: auth.token.expires_in_seconds,
        state: pre_auth.state,
        id_token: id_token.as_jws_token
      })
    end
  end

  describe '#redirect_uri' do
    it 'includes expires_in, id_token and state' do
      expect(subject.redirect_uri).to include("#{pre_auth.redirect_uri}#expires_in=#{auth.token.expires_in_seconds}&" \
        "state=#{pre_auth.state}&" \
        "id_token=#{id_token.as_jws_token}")
    end

    it 'does not include access_token' do
      expect(subject.redirect_uri).not_to include('access_token')
    end
  end
end
