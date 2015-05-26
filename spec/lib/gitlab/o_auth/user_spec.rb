require 'spec_helper'

describe Gitlab::OAuth::User do
  let(:oauth_user) { Gitlab::OAuth::User.new(auth_hash) }
  let(:gl_user) { oauth_user.gl_user }
  let(:uid) { 'my-uid' }
  let(:provider) { 'my-provider' }
  let(:auth_hash) { double(uid: uid, provider: provider, info: double(info_hash)) }
  let(:info_hash) do
    {
      nickname: '-john+gitlab-ETC%.git@gmail.com',
      name: 'John',
      email: 'john@mail.com'
    }
  end

  describe :persisted? do
    let!(:existing_user) { create(:omniauth_user, extern_uid: 'my-uid', provider: 'my-provider') }

    it "finds an existing user based on uid and provider (facebook)" do
      expect(oauth_user.persisted?).to be_truthy
    end

    it "returns false if use is not found in database" do
      allow(auth_hash).to receive(:uid).and_return('non-existing')
      expect(oauth_user.persisted?).to be_falsey
    end
  end

  describe :save do
    let(:provider) { 'twitter' }

    describe 'signup' do
      context "with allow_single_sign_on enabled" do
        before do
          allow(Gitlab.config.omniauth).
            to receive(:allow_single_sign_on).and_return(true)
        end

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
      before do
        allow(Gitlab.config.omniauth).
          to receive(:allow_single_sign_on).and_return(true)
      end

      context 'signup' do
        context 'dont block on create' do
          before do
            allow(Gitlab.config.omniauth).
              to receive(:block_auto_created_users).and_return(false)
          end

          it do
            oauth_user.save
            expect(gl_user).to be_valid
            expect(gl_user).not_to be_blocked
          end
        end

        context 'block on create' do
          before do
            allow(Gitlab.config.omniauth).
              to receive(:block_auto_created_users).and_return(true)
          end

          it do
            oauth_user.save
            expect(gl_user).to be_valid
            expect(gl_user).to be_blocked
          end
        end
      end

      context 'sign-in' do
        before do
          oauth_user.save
          oauth_user.gl_user.activate
        end

        context 'dont block on create' do
          before do
            allow(Gitlab.config.omniauth).
              to receive(:block_auto_created_users).and_return(false)
          end

          it do
            oauth_user.save
            expect(gl_user).to be_valid
            expect(gl_user).not_to be_blocked
          end
        end

        context 'block on create' do
          before do
            allow(Gitlab.config.omniauth).
              to receive(:block_auto_created_users).and_return(true)
          end

          it do
            oauth_user.save
            expect(gl_user).to be_valid
            expect(gl_user).not_to be_blocked
          end
        end
      end
    end
  end
end
