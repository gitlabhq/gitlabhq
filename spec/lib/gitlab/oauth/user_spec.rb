require 'spec_helper'

describe Gitlab::OAuth::User do
  let(:oauth_user) { Gitlab::OAuth::User.new(auth_hash) }
  let(:gl_user) { oauth_user.gl_user }
  let(:uid) { 'my-uid' }
  let(:provider) { 'my-provider' }
  let(:auth_hash) { double(uid: uid, provider: provider, info: double(info_hash)) }
  let(:info_hash) do
    {
      nickname: 'john',
      name: 'John',
      email: 'john@mail.com'
    }
  end

  describe :persisted? do
    let!(:existing_user) { create(:user, extern_uid: 'my-uid', provider: 'my-provider') }

    it "finds an existing user based on uid and provider (facebook)" do
      auth = double(info: double(name: 'John'), uid: 'my-uid', provider: 'my-provider')
      expect( oauth_user.persisted? ).to be_true
    end

    it "returns false if use is not found in database" do
      auth_hash.stub(uid: 'non-existing')
      expect( oauth_user.persisted? ).to be_false
    end
  end

  describe :save do
    let(:provider) { 'twitter' }

    it "creates a user from Omniauth" do
      oauth_user.save

      expect(gl_user).to be_valid
      expect(gl_user.extern_uid).to eql uid
      expect(gl_user.provider).to eql 'twitter'
    end
  end

    context "twitter" do
      let(:provider) { 'twitter' }

      it "creates a user from Omniauth" do
        oauth_user.save

        expect(gl_user).to be_valid
        expect(gl_user.extern_uid).to eql uid
        expect(gl_user.provider).to eql 'twitter'
      end
    end
  end
end
