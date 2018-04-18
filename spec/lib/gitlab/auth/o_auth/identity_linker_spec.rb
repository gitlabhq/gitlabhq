require 'spec_helper'

describe Gitlab::Auth::OAuth::IdentityLinker do
  let(:user) { create(:user) }
  let(:provider) { 'twitter' }
  let(:uid) { user.email }
  let(:oauth) { { 'provider' => provider, 'uid' => uid } }

  subject { described_class.new(user, oauth) }

  context 'linked identity exists' do
    let!(:identity) { user.identities.create!(provider: provider, extern_uid: uid) }

    it "doesn't create new identity" do
      expect { subject.create_or_update }.not_to change { Identity.count }
    end
  end

  context 'identity needs to be created' do
    it 'creates linked identity' do
      expect { subject.create_or_update }.to change { user.identities.count }
    end

    it 'sets identity provider' do
      subject.create_or_update

      expect(user.identities.last.provider).to eq provider
    end

    it 'sets identity extern_uid' do
      subject.create_or_update

      expect(user.identities.last.extern_uid).to eq uid
    end

    it 'sets #created? to true' do
      subject.create_or_update

      expect(subject).to be_created
    end
  end
end
