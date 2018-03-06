require 'spec_helper'

describe Gitlab::Auth::LDAP::User do
  let(:ldap_user) { described_class.new(auth_hash) }
  let(:gl_user) { ldap_user.gl_user }
  let(:info) do
    {
      name: 'John',
      email: 'john@example.com',
      nickname: 'john'
    }
  end
  let(:auth_hash) do
    OmniAuth::AuthHash.new(uid: 'uid=John Smith,ou=People,dc=example,dc=com', provider: 'ldapmain', info: info)
  end
  let(:ldap_user_upper_case) { described_class.new(auth_hash_upper_case) }
  let(:info_upper_case) do
    {
      name: 'John',
      email: 'John@Example.com', # Email address has upper case chars
      nickname: 'john'
    }
  end
  let(:auth_hash_upper_case) do
    OmniAuth::AuthHash.new(uid: 'uid=John Smith,ou=People,dc=example,dc=com', provider: 'ldapmain', info: info_upper_case)
  end

  describe '#changed?' do
    it "marks existing ldap user as changed" do
      create(:omniauth_user, extern_uid: 'uid=John Smith,ou=People,dc=example,dc=com', provider: 'ldapmain')
      expect(ldap_user.changed?).to be_truthy
    end

    it "marks existing non-ldap user if the email matches as changed" do
      create(:user, email: 'john@example.com')
      expect(ldap_user.changed?).to be_truthy
    end

    it "does not mark existing ldap user as changed" do
      create(:omniauth_user, email: 'john@example.com', extern_uid: 'uid=john smith,ou=people,dc=example,dc=com', provider: 'ldapmain')
      expect(ldap_user.changed?).to be_falsey
    end
  end

  describe '.find_by_uid_and_provider' do
    let(:dn) { 'CN=John Åström, CN=Users, DC=Example, DC=com' }

    it 'retrieves the correct user' do
      special_info = {
        name: 'John Åström',
        email: 'john@example.com',
        nickname: 'jastrom'
      }
      special_hash = OmniAuth::AuthHash.new(uid: dn, provider: 'ldapmain', info: special_info)
      special_chars_user = described_class.new(special_hash)
      user = special_chars_user.save

      expect(described_class.find_by_uid_and_provider(dn, 'ldapmain')).to eq user
    end
  end

  describe 'find or create' do
    it "finds the user if already existing" do
      create(:omniauth_user, extern_uid: 'uid=john smith,ou=people,dc=example,dc=com', provider: 'ldapmain')

      expect { ldap_user.save }.not_to change { User.count }
    end

    it "connects to existing non-ldap user if the email matches" do
      existing_user = create(:omniauth_user, email: 'john@example.com', provider: "twitter")
      expect { ldap_user.save }.not_to change { User.count }

      existing_user.reload
      expect(existing_user.ldap_identity.extern_uid).to eql 'uid=john smith,ou=people,dc=example,dc=com'
      expect(existing_user.ldap_identity.provider).to eql 'ldapmain'
    end

    it 'connects to existing ldap user if the extern_uid changes' do
      existing_user = create(:omniauth_user, email: 'john@example.com', extern_uid: 'old-uid', provider: 'ldapmain')
      expect { ldap_user.save }.not_to change { User.count }

      existing_user.reload
      expect(existing_user.ldap_identity.extern_uid).to eql 'uid=john smith,ou=people,dc=example,dc=com'
      expect(existing_user.ldap_identity.provider).to eql 'ldapmain'
      expect(existing_user.id).to eql ldap_user.gl_user.id
    end

    it 'connects to existing ldap user if the extern_uid changes and email address has upper case characters' do
      existing_user = create(:omniauth_user, email: 'john@example.com', extern_uid: 'old-uid', provider: 'ldapmain')
      expect { ldap_user_upper_case.save }.not_to change { User.count }

      existing_user.reload
      expect(existing_user.ldap_identity.extern_uid).to eql 'uid=john smith,ou=people,dc=example,dc=com'
      expect(existing_user.ldap_identity.provider).to eql 'ldapmain'
      expect(existing_user.id).to eql ldap_user.gl_user.id
    end

    it 'maintains an identity per provider' do
      existing_user = create(:omniauth_user, email: 'john@example.com', provider: 'twitter')
      expect(existing_user.identities.count).to be(1)

      ldap_user.save
      expect(ldap_user.gl_user.identities.count).to be(2)

      # Expect that find_by provider only returns a single instance of an identity and not an Enumerable
      expect(ldap_user.gl_user.identities.find_by(provider: 'twitter')).to be_instance_of Identity
      expect(ldap_user.gl_user.identities.find_by(provider: auth_hash.provider)).to be_instance_of Identity
    end

    it "creates a new user if not found" do
      expect { ldap_user.save }.to change { User.count }.by(1)
    end

    context 'when signup is disabled' do
      before do
        stub_application_setting signup_enabled: false
      end

      it 'creates the user' do
        ldap_user.save

        expect(gl_user).to be_persisted
      end
    end

    context 'when user confirmation email is enabled' do
      before do
        stub_application_setting send_user_confirmation_email: true
      end

      it 'creates and confirms the user anyway' do
        ldap_user.save

        expect(gl_user).to be_persisted
        expect(gl_user).to be_confirmed
      end
    end
  end

  describe 'updating email' do
    context "when LDAP sets an email" do
      it "has a real email" do
        expect(ldap_user.gl_user.email).to eq(info[:email])
      end

      it "has email set as synced" do
        expect(ldap_user.gl_user.user_synced_attributes_metadata.email_synced).to be_truthy
      end

      it "has email set as read-only" do
        expect(ldap_user.gl_user.read_only_attribute?(:email)).to be_truthy
      end

      it "has synced attributes provider set to ldapmain" do
        expect(ldap_user.gl_user.user_synced_attributes_metadata.provider).to eql 'ldapmain'
      end
    end

    context "when LDAP doesn't set an email" do
      before do
        info.delete(:email)
      end

      it "has a temp email" do
        expect(ldap_user.gl_user.temp_oauth_email?).to be_truthy
      end

      it "has email set as not synced" do
        expect(ldap_user.gl_user.user_synced_attributes_metadata.email_synced).to be_falsey
      end

      it "does not have email set as read-only" do
        expect(ldap_user.gl_user.read_only_attribute?(:email)).to be_falsey
      end
    end
  end

  describe 'blocking' do
    def configure_block(value)
      allow_any_instance_of(Gitlab::Auth::LDAP::Config)
          .to receive(:block_auto_created_users).and_return(value)
    end

    context 'signup' do
      context 'dont block on create' do
        before do
          configure_block(false)
        end

        it do
          ldap_user.save
          expect(gl_user).to be_valid
          expect(gl_user).not_to be_blocked
        end
      end

      context 'block on create' do
        before do
          configure_block(true)
        end

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
        before do
          configure_block(false)
        end

        it do
          ldap_user.save
          expect(gl_user).to be_valid
          expect(gl_user).not_to be_blocked
        end
      end

      context 'block on create' do
        before do
          configure_block(true)
        end

        it do
          ldap_user.save
          expect(gl_user).to be_valid
          expect(gl_user).not_to be_blocked
        end
      end
    end
  end
end
