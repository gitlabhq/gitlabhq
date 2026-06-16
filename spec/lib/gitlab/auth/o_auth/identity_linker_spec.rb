# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::OAuth::IdentityLinker do
  let(:user) { create(:user) }
  let(:provider) { 'twitter' }
  let(:uid) { user.email }
  let(:oauth) { { 'provider' => provider, 'uid' => uid } }

  subject(:identity_linker) { described_class.new(user, oauth) }

  context 'linked identity exists' do
    let!(:identity) { user.identities.create!(provider: provider, extern_uid: uid) }

    it "doesn't create new identity" do
      expect { identity_linker.link }.not_to change { ::Identity.count }
    end

    it "sets #changed? to false" do
      identity_linker.link

      expect(identity_linker).not_to be_changed
    end
  end

  context 'identity already linked to different user' do
    let!(:identity) { create(:identity, provider: provider, extern_uid: uid) }

    it "#changed? returns false" do
      identity_linker.link

      expect(identity_linker).not_to be_changed
    end

    it 'exposes error message' do
      expect(identity_linker.error_message).to eq "Extern uid has already been taken. " \
        "Please contact your administrator to generate a unique extern_uid / NameID"
    end
  end

  context 'identity needs to be created' do
    it 'creates linked identity' do
      expect { identity_linker.link }.to change { user.identities.count }
    end

    it 'sets identity provider' do
      identity_linker.link

      expect(user.identities.last.provider).to eq provider
    end

    it 'sets identity extern_uid' do
      identity_linker.link

      expect(user.identities.last.extern_uid).to eq uid
    end

    it 'sets #changed? to true' do
      identity_linker.link

      expect(identity_linker).to be_changed
    end
  end
end
