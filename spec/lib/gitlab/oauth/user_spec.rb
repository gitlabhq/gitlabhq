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
    let!(:existing_user) { create(:omniauth_user, extern_uid: 'my-uid', provider: 'my-provider') }

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

    describe 'signup' do
      context "with allow_single_sign_on enabled" do
        before { Gitlab.config.omniauth.stub allow_single_sign_on: true }

        it "creates a user from Omniauth" do
          oauth_user.save

          expect(gl_user).to be_valid
          identity = gl_user.identities.first
          expect(identity.extern_uid).to eql uid
          expect(identity.provider).to eql 'twitter'
        end
      end

      context "with allow_single_sign_on disabled (Default)" do
        it "throws an error" do
          expect{ oauth_user.save }.to raise_error StandardError
        end
      end
    end

    describe 'blocking' do
      let(:provider) { 'twitter' }
      before { Gitlab.config.omniauth.stub allow_single_sign_on: true }

      context 'signup' do
        context 'dont block on create' do
          before { Gitlab.config.omniauth.stub block_auto_created_users: false }

          it do
            oauth_user.save
            gl_user.should be_valid
            gl_user.should_not be_blocked
          end
        end

        context 'block on create' do
          before { Gitlab.config.omniauth.stub block_auto_created_users: true }

          it do
            oauth_user.save
            gl_user.should be_valid
            gl_user.should be_blocked
          end
        end
      end

      context 'sign-in' do
        before do
          oauth_user.save
          oauth_user.gl_user.activate
        end

        context 'dont block on create' do
          before { Gitlab.config.omniauth.stub block_auto_created_users: false }

          it do
            oauth_user.save
            gl_user.should be_valid
            gl_user.should_not be_blocked
          end
        end

        context 'block on create' do
          before { Gitlab.config.omniauth.stub block_auto_created_users: true }

          it do
            oauth_user.save
            gl_user.should be_valid
            gl_user.should_not be_blocked
          end
        end
      end
    end
  end
end
