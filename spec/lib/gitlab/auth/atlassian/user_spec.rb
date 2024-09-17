# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::Atlassian::User do
  let_it_be(:organization) { create(:organization) }
  let(:oauth_user) { described_class.new(oauth, organization_id: organization.id) }
  let(:gl_user) { oauth_user.gl_user }
  let(:extern_uid) { generate(:username) }
  let(:oauth) do
    OmniAuth::AuthHash.new(
      uid: extern_uid,
      provider: 'atlassian_oauth2',
      info: { name: 'John', email: 'john@mail.com' },
      credentials: credentials)
  end

  let(:credentials) do
    {
      token: SecureRandom.alphanumeric(1254),
      refresh_token: SecureRandom.alphanumeric(45),
      expires_at: 2.weeks.from_now.to_i,
      expires: true
    }
  end

  describe '.assign_identity_from_auth_hash!' do
    let(:auth_hash) { ::Gitlab::Auth::Atlassian::AuthHash.new(oauth) }
    let(:identity) { described_class.assign_identity_from_auth_hash!(Atlassian::Identity.new, auth_hash) }

    it_behaves_like 'an atlassian identity'
  end

  describe '#save' do
    context 'for an existing user' do
      context 'with an existing Atlassian Identity' do
        let!(:existing_user) { create(:atlassian_user, extern_uid: extern_uid) }
        let(:identity) { gl_user.atlassian_identity }

        before do
          oauth_user.save # rubocop:disable Rails/SaveBang
        end

        it 'finds the existing user and identity' do
          expect(gl_user.id).to eq(existing_user.id)
          expect(identity.id).to eq(existing_user.atlassian_identity.id)
        end

        it_behaves_like 'an atlassian identity'
      end

      context 'for a new user' do
        it 'creates the user and identity' do
          oauth_user.save # rubocop:disable Rails/SaveBang

          expect(gl_user).to be_valid
        end
      end
    end
  end
end
