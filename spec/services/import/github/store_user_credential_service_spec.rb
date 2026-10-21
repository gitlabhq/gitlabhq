# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::Github::StoreUserCredentialService, :freeze_time, feature_category: :importers do
  let_it_be(:user) { create(:user) }

  let(:token_response) do
    {
      'access_token' => 'ghu_token',
      'refresh_token' => 'ghr_token',
      'expires_in' => 28800,
      'refresh_token_expires_in' => 15897600,
      'scope' => 'repo,read:org'
    }
  end

  let(:token) { OAuth2::AccessToken.from_hash(OAuth2::Client.new('id', 'secret'), token_response) }

  subject(:execute) { described_class.new(user, token, provider_host: 'github.com').execute }

  before do
    stub_request(:get, 'https://api.github.com/user')
      .with(headers: { 'Authorization' => 'token ghu_token' })
      .to_return(status: 200, body: { id: 583231, login: 'octocat' }.to_json,
        headers: { 'Content-Type' => 'application/json' })
  end

  it 'stores the whole token for the GitHub account' do
    expect(execute).to be_success

    expect(Import::UserCredential.sole).to have_attributes(
      user: user,
      provider: 'github',
      provider_host: 'github.com',
      provider_account_xid: 583231,
      access_token: 'ghu_token',
      refresh_token: 'ghr_token',
      expires_at: 28800.seconds.from_now,
      refresh_token_expires_at: 15897600.seconds.from_now,
      scopes: 'repo,read:org'
    )
  end

  context 'when the token does not expire' do
    let(:token_response) { { 'access_token' => 'ghu_token', 'scope' => 'repo,read:org' } }

    it 'stores the token without a refresh token or expiry' do
      execute

      expect(Import::UserCredential.sole).to have_attributes(
        access_token: 'ghu_token', refresh_token: nil, expires_at: nil, refresh_token_expires_at: nil
      )
    end
  end

  context 'when the GitHub account lookup fails' do
    before do
      stub_request(:get, 'https://api.github.com/user').to_return(status: 401)
    end

    it 'returns an error without storing a credential or logging the token' do
      expect(Gitlab::GithubImport::Logger).to receive(:error)
        .with(hash_including(message: 'Failed to store GitHub OAuth credential', Labkit::Fields::GL_USER_ID => user.id))
        .and_wrap_original do |method, payload|
          expect(payload.to_s).not_to include('ghu_token')
          method.call(payload)
        end

      expect(execute).to be_error
      expect(Import::UserCredential.count).to eq(0)
    end
  end

  context 'when the credential keeps conflicting with a concurrent sign-in' do
    before do
      allow(Import::UserCredential).to receive(:store!).and_raise(ActiveRecord::RecordNotUnique)
    end

    it 'returns an error' do
      expect(Gitlab::GithubImport::Logger).to receive(:error)
        .with(hash_including(Labkit::Fields::ERROR_TYPE => 'ActiveRecord::RecordNotUnique'))

      expect(execute).to be_error
    end
  end
end
