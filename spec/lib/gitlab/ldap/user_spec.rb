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
    double(uid: 'my-uid', provider: 'ldapmain', info: double(info))
  end

  describe :changed? do
    it "marks existing ldap user as changed" do
      existing_user = create(:omniauth_user, extern_uid: 'my-uid', provider: 'ldapmain')
      expect(ldap_user.changed?).to be_truthy
    end

    it "marks existing non-ldap user if the email matches as changed" do
      existing_user = create(:user, email: 'john@example.com')
      expect(ldap_user.changed?).to be_truthy
    end

    it "dont marks existing ldap user as changed" do
      existing_user = create(:omniauth_user, email: 'john@example.com', extern_uid: 'my-uid', provider: 'ldapmain')
      expect(ldap_user.changed?).to be_falsey
    end
  end

  describe :find_or_create do
    it "finds the user if already existing" do
      existing_user = create(:omniauth_user, extern_uid: 'my-uid', provider: 'ldapmain')

      expect{ ldap_user.save }.to_not change{ User.count }
    end

    it "connects to existing non-ldap user if the email matches" do
      existing_user = create(:omniauth_user, email: 'john@example.com', provider: "twitter")
      expect{ ldap_user.save }.to_not change{ User.count }

      existing_user.reload
      expect(existing_user.ldap_identity.extern_uid).to eql 'my-uid'
      expect(existing_user.ldap_identity.provider).to eql 'ldapmain'
    end

    it "creates a new user if not found" do
      expect{ ldap_user.save }.to change{ User.count }.by(1)
    end
  end


  describe 'blocking' do
    context 'signup' do
      context 'dont block on create' do
        before { Gitlab::LDAP::Config.any_instance.stub block_auto_created_users: false }

        it do
          ldap_user.save
          expect(gl_user).to be_valid
          expect(gl_user).not_to be_blocked
        end
      end

      context 'block on create' do
        before { Gitlab::LDAP::Config.any_instance.stub block_auto_created_users: true }

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
        before { Gitlab::LDAP::Config.any_instance.stub block_auto_created_users: false }

        it do
          ldap_user.save
          expect(gl_user).to be_valid
          expect(gl_user).not_to be_blocked
        end
      end

      context 'block on create' do
        before { Gitlab::LDAP::Config.any_instance.stub block_auto_created_users: true }

        it do
          ldap_user.save
          expect(gl_user).to be_valid
          expect(gl_user).not_to be_blocked
        end
      end
    end
  end
end
