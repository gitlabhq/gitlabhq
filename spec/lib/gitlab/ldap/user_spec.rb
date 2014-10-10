require 'spec_helper'

describe Gitlab::LDAP::User do
  let(:gl_user) { Gitlab::LDAP::User.new(auth_hash) }
  let(:info) do
    {
      name: 'John',
      email: 'john@example.com',
      nickname: 'john'
    }
  end
  let(:auth_hash) do
    double(uid: 'my-uid', provider: 'ldap', info: double(info))
  end

  describe :find_or_create do
    it "finds the user if already existing" do
      existing_user = create(:user, extern_uid: 'my-uid', provider: 'ldap')

      expect{ gl_user.save }.to_not change{ User.count }
    end

    it "connects to existing non-ldap user if the email matches" do
      existing_user = create(:user, email: 'john@example.com')
      expect{ gl_user.save }.to_not change{ User.count }

      existing_user.reload
      expect(existing_user.extern_uid).to eql 'my-uid'
      expect(existing_user.provider).to eql 'ldap'
    end

    it "creates a new user if not found" do
      expect{ gl_user.save }.to change{ User.count }.by(1)
    end
  end

  describe "authenticate" do
    let(:login) { 'john' }
    let(:password) { 'my-secret' }

    before {
      Gitlab.config.ldap['enabled'] = true
      Gitlab.config.ldap['user_filter'] = 'employeeType=developer'
    }
    after  { Gitlab.config.ldap['enabled'] = false }

    it "send an authentication request to ldap" do
      expect( Gitlab::LDAP::User.adapter ).to receive(:bind_as)
      Gitlab::LDAP::User.authenticate(login, password)
    end
  end
end
