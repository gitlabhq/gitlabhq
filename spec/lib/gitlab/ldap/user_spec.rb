require 'spec_helper'

describe Gitlab::LDAP::User do
  let(:ldap_user) { Gitlab::LDAP::User.new(auth_hash) }
  let(:gl_user) { ldap_user.gl_user }
  let(:info) do
    {
      name: 'John',
      email: 'john@example.com',
      nickname: 'john'
    }
  end
  let(:auth_hash) do
    OmniAuth::AuthHash.new(uid: 'my-uid', provider: 'ldapmain', info: info)
  end
  let(:ldap_user_upper_case) { Gitlab::LDAP::User.new(auth_hash_upper_case) }
  let(:info_upper_case) do
    {
      name: 'John',
      email: 'John@Example.com', # Email address has upper case chars
      nickname: 'john'
    }
  end
  let(:auth_hash_upper_case) do
    OmniAuth::AuthHash.new(uid: 'my-uid', provider: 'ldapmain', info: info_upper_case)
  end

  describe :changed? do
    it "marks existing ldap user as changed" do
      create(:omniauth_user, extern_uid: 'my-uid', provider: 'ldapmain')
      expect(ldap_user.changed?).to be_truthy
    end

    it "marks existing non-ldap user if the email matches as changed" do
      create(:user, email: 'john@example.com')
      expect(ldap_user.changed?).to be_truthy
    end

    it "dont marks existing ldap user as changed" do
      create(:omniauth_user, email: 'john@example.com', extern_uid: 'my-uid', provider: 'ldapmain')
      expect(ldap_user.changed?).to be_falsey
    end
  end

  describe :find_or_create do
    it "finds the user if already existing" do
      create(:omniauth_user, extern_uid: 'my-uid', provider: 'ldapmain')

      expect{ ldap_user.save }.not_to change{ User.count }
    end

    it "connects to existing non-ldap user if the email matches" do
      existing_user = create(:omniauth_user, email: 'john@example.com', provider: "twitter")
      expect{ ldap_user.save }.not_to change{ User.count }

      existing_user.reload
      expect(existing_user.ldap_identity.extern_uid).to eql 'my-uid'
      expect(existing_user.ldap_identity.provider).to eql 'ldapmain'
    end

    it 'connects to existing ldap user if the extern_uid changes' do
      existing_user = create(:omniauth_user, email: 'john@example.com', extern_uid: 'old-uid', provider: 'ldapmain')
      expect{ ldap_user.save }.not_to change{ User.count }

      existing_user.reload
      expect(existing_user.ldap_identity.extern_uid).to eql 'my-uid'
      expect(existing_user.ldap_identity.provider).to eql 'ldapmain'
      expect(existing_user.id).to eql ldap_user.gl_user.id
    end

    it 'connects to existing ldap user if the extern_uid changes and email address has upper case characters' do
      existing_user = create(:omniauth_user, email: 'john@example.com', extern_uid: 'old-uid', provider: 'ldapmain')
      expect{ ldap_user_upper_case.save }.not_to change{ User.count }

      existing_user.reload
      expect(existing_user.ldap_identity.extern_uid).to eql 'my-uid'
      expect(existing_user.ldap_identity.provider).to eql 'ldapmain'
      expect(existing_user.id).to eql ldap_user.gl_user.id
    end

    it 'maintains an identity per provider' do
      existing_user = create(:omniauth_user, email: 'john@example.com', provider: 'twitter')
      expect(existing_user.identities.count).to eql(1)

      ldap_user.save
      expect(ldap_user.gl_user.identities.count).to eql(2)

      # Expect that find_by provider only returns a single instance of an identity and not an Enumerable
      expect(ldap_user.gl_user.identities.find_by(provider: 'twitter')).to be_instance_of Identity
      expect(ldap_user.gl_user.identities.find_by(provider: auth_hash.provider)).to be_instance_of Identity
    end

    it "creates a new user if not found" do
      expect{ ldap_user.save }.to change{ User.count }.by(1)
    end
  end

  describe 'blocking' do
    def configure_block(value)
      allow_any_instance_of(Gitlab::LDAP::Config).
        to receive(:block_auto_created_users).and_return(value)
    end

    context 'signup' do
      context 'dont block on create' do
        before { configure_block(false) }

        it do
          ldap_user.save
          expect(gl_user).to be_valid
          expect(gl_user).not_to be_blocked
        end
      end

      context 'block on create' do
        before { configure_block(true) }

        it do
          ldap_user.save
          expect(gl_user).to be_valid
          expect(gl_user).to be_blocked
        end
      end
    end

    context 'sign-in' do
      before do
        ldap_user.save
        ldap_user.gl_user.activate
      end

      context 'dont block on create' do
        before { configure_block(false) }

        it do
          ldap_user.save
          expect(gl_user).to be_valid
          expect(gl_user).not_to be_blocked
        end
      end

      context 'block on create' do
        before { configure_block(true) }

        it do
          ldap_user.save
          expect(gl_user).to be_valid
          expect(gl_user).not_to be_blocked
        end
      end
    end
  end
end
