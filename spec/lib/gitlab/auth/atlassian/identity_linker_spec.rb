# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::Atlassian::IdentityLinker do
  let(:user) { create(:user) }
  let(:extern_uid) { generate(:username) }
  let(:oauth) do
    OmniAuth::AuthHash.new(
      uid: extern_uid,
      provider: 'atlassian_oauth2',
      info: { name: 'John', email: 'john@mail.com' },
      credentials: credentials
    )
  end

  let(:credentials) do
    {
      token: SecureRandom.alphanumeric(4550),
      refresh_token: SecureRandom.alphanumeric(1500),
      expires_at: 2.weeks.from_now.to_i,
      expires: true
    }
  end

  subject { described_class.new(user, oauth) }

  context 'linked identity exists' do
    let!(:identity) { create(:atlassian_identity, user: user, extern_uid: extern_uid) }

    before do
      subject.link
    end

    it 'sets #changed? to false' do
      expect(subject).not_to be_changed
    end

    it 'does not mark as failed' do
      expect(subject).not_to be_failed
    end
  end

  context 'identity already linked to different user' do
    let!(:identity) { create(:atlassian_identity, extern_uid: extern_uid) }

    it 'sets #changed? to false' do
      subject.link

      expect(subject).not_to be_changed
    end

    it 'exposes error message' do
      expect(subject.error_message).to eq 'Extern uid has already been taken'
    end
  end

  context 'identity needs to be created' do
    let(:identity) { user.atlassian_identity }

    before do
      subject.link
    end

    it_behaves_like 'an atlassian identity'

    it 'sets #changed? to true' do
      expect(subject).to be_changed
    end
  end
end
