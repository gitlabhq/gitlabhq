# frozen_string_literal: true

require 'rails_helper'

describe Doorkeeper::OAuth::IdTokenTokenRequest do
  subject do
    described_class.new(pre_auth, owner)
  end

  let :application do
    FactoryBot.create(:application, scopes: 'public')
  end

  let :pre_auth do
    server = Doorkeeper.configuration
    allow(server).to receive(:grant_flows).and_return(['implicit_oidc'])

    client = Doorkeeper::OAuth::Client.new(application)

    attributes = {
      client_id: client.uid,
      response_type: 'id_token token',
      redirect_uri: 'https://app.com/callback',
      scope: 'public',
      nonce: '12345',
    }

    pre_auth = Doorkeeper::OAuth::PreAuthorization.new(server, attributes)
    pre_auth.authorizable?
    pre_auth
  end

  let(:owner) { build_stubbed(:user) }

  # just to make sure self created pre_auth is authorizable
  it 'pre_auth should be valid' do
    expect(pre_auth).to be_authorizable
  end

  it 'creates an access token' do
    expect do
      subject.authorize
    end.to change { Doorkeeper::AccessToken.count }.by(1)
  end

  it 'returns id_token token response' do
    expect(subject.authorize).to be_a(Doorkeeper::OAuth::IdTokenTokenResponse)
  end
end
