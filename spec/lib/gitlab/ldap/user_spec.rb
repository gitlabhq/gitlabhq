require 'spec_helper'

describe Gitlab::LDAP::User do
  include LdapHelpers

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
    OmniAuth::AuthHash.new(uid: 'my-uid', provider: 'ldapmain', info: info)
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
    OmniAuth::AuthHash.new(uid: 'my-uid', provider: 'ldapmain', info: info_upper_case)
  end

  describe '#initialize' do
    it 'calls #set_external_with_external_groups' do
      expect_any_instance_of(described_class).to receive(:set_external_with_external_groups)
      ldap_user
    end
  end

  describe '#changed?' do
    it "marks existing ldap user as changed" do
      create(:omniauth_user, extern_uid: 'my-uid', provider: 'ldapmain')
      expect(ldap_user.changed?).to be_truthy
    end

    it "marks existing non-ldap user if the email matches as changed" do
      create(:user, email: 'john@example.com')
      expect(ldap_user.changed?).to be_truthy
    end

    it "does not mark existing ldap user as changed" do
      create(:omniauth_user, email: 'john@example.com', extern_uid: 'my-uid', provider: 'ldapmain', external_email: true, email_provider: 'ldapmain')
      expect(ldap_user.changed?).to be_falsey
    end
  end

  describe '.find_by_uid_and_provider' do
    it 'retrieves the correct user' do
      special_info = {
        name: 'John Åström',
        email: 'john@example.com',
        nickname: 'jastrom'
      }
      special_hash = OmniAuth::AuthHash.new(uid: 'CN=John Åström,CN=Users,DC=Example,DC=com', provider: 'ldapmain', info: special_info)
      special_chars_user = described_class.new(special_hash)
      user = special_chars_user.save

      expect(described_class.find_by_uid_and_provider(special_hash.uid, special_hash.provider)).to eq user
    end
  end

  describe 'find or create' do
    it "finds the user if already existing" do
      create(:omniauth_user, extern_uid: 'my-uid', provider: 'ldapmain')

      expect { ldap_user.save }.not_to change { User.count }
    end

    it "connects to existing non-ldap user if the email matches" do
      existing_user = create(:omniauth_user, email: 'john@example.com', provider: "twitter")
      expect { ldap_user.save }.not_to change { User.count }

      existing_user.reload
      expect(existing_user.ldap_identity.extern_uid).to eql 'my-uid'
      expect(existing_user.ldap_identity.provider).to eql 'ldapmain'
    end

    it 'connects to existing ldap user if the extern_uid changes' do
      existing_user = create(:omniauth_user, email: 'john@example.com', extern_uid: 'old-uid', provider: 'ldapmain')
      expect { ldap_user.save }.not_to change { User.count }

      existing_user.reload
      expect(existing_user.ldap_identity.extern_uid).to eql 'my-uid'
      expect(existing_user.ldap_identity.provider).to eql 'ldapmain'
      expect(existing_user.id).to eql ldap_user.gl_user.id
    end

    it 'connects to existing ldap user if the extern_uid changes and email address has upper case characters' do
      existing_user = create(:omniauth_user, email: 'john@example.com', extern_uid: 'old-uid', provider: 'ldapmain')
      expect { ldap_user_upper_case.save }.not_to change { User.count }

      existing_user.reload
      expect(existing_user.ldap_identity.extern_uid).to eql 'my-uid'
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

      it "has external_email set to true" do
        expect(ldap_user.gl_user.external_email?).to be(true)
      end

      it "has email_provider set to provider" do
        expect(ldap_user.gl_user.email_provider).to eql 'ldapmain'
      end
    end

    context "when LDAP doesn't set an email" do
      before do
        info.delete(:email)
      end

      it "has a temp email" do
        expect(ldap_user.gl_user.temp_oauth_email?).to be(true)
      end

      it "has external_email set to false" do
        expect(ldap_user.gl_user.external_email?).to be(false)
      end
    end
  end

  describe 'blocking' do
    def configure_block(value)
      stub_ldap_config(block_auto_created_users: value)
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

  describe '#set_external_with_external_groups' do
    context 'when the LDAP user is in an external group' do
      before do
        expect(ldap_user).to receive(:in_any_external_group?).and_return(true)
      end

      it 'sets the GitLab user external flag to true' do
        expect do
          ldap_user.set_external_with_external_groups
        end.to change { gl_user.external }.from(false).to(true)
      end
    end

    context 'when the LDAP user is not in an external group' do
      before do
        expect(ldap_user).to receive(:in_any_external_group?).and_return(false)
      end

      it 'sets the GitLab user external flag to true' do
        gl_user.external = true
        gl_user.save

        expect do
          ldap_user.set_external_with_external_groups
        end.to change { gl_user.external }.from(true).to(false)
      end
    end
  end

  describe '#in_any_external_group?' do
    context 'when there is an external group' do
      before do
        stub_ldap_config(external_groups: ['foo'])
      end

      context 'when the user is in an external group' do
        before do
          expect(ldap_user).to receive(:in_group?).and_return(true)
        end

        it 'returns true' do
          expect(ldap_user.in_any_external_group?).to be_truthy
        end
      end

      context 'when the user is not in an external group' do
        before do
          expect(ldap_user).to receive(:in_group?).and_return(false)
        end

        it 'returns false' do
          expect(ldap_user.in_any_external_group?).to be_falsey
        end
      end
    end

    context 'when are no external groups' do
      before do
        stub_ldap_config(external_groups: [])
      end

      it 'returns false' do
        expect(ldap_user.in_any_external_group?).to be_falsey
      end
    end
  end

  describe '#in_group?' do
    let(:proxy) { double(:proxy) }
    let(:group) { 'foo' }
    let(:member_dns_in_group) { ['uid=alice,ou=people,dc=example,dc=com'] }
    subject { ldap_user.in_group?(proxy, group) }

    before do
      expect(proxy).to receive(:dns_for_group_cn).with(group).and_return(member_dns_in_group)
    end

    context 'when the LDAP user is in the group' do
      before do
        member_dns_in_group << ldap_user.auth_hash.uid
      end

      it 'returns true' do
        expect(subject).to be_truthy
      end
    end

    context 'when the LDAP user is not in the group' do
      it 'returns false' do
        expect(subject).to be_falsey
      end
    end
  end
end
