require 'spec_helper'

describe Gitlab::LDAP::Authentication do
  let(:klass) { Gitlab::LDAP::Authentication }
  let(:user) { create(:omniauth_user, extern_uid: dn) }
  let(:dn) { 'uid=john,ou=people,dc=example,dc=com' }
  let(:login) { 'john' }
  let(:password) { 'password' }

  describe :login do
    let(:adapter) { double :adapter }
    before do
      Gitlab::LDAP::Config.stub(enabled?: true)
    end

    it "finds the user if authentication is successful" do
      user
      # try only to fake the LDAP call
      klass.any_instance.stub(adapter: double(:adapter,
        bind_as: double(:ldap_user, dn: dn)
      ))
      expect(klass.login(login, password)).to be_true
    end

    it "is false if the user does not exist" do
      # try only to fake the LDAP call
      klass.any_instance.stub(adapter: double(:adapter,
        bind_as: double(:ldap_user, dn: dn)
      ))
      expect(klass.login(login, password)).to be_false
    end

    it "is false if authentication fails" do
      user
      # try only to fake the LDAP call
      klass.any_instance.stub(adapter: double(:adapter, bind_as: nil))
      expect(klass.login(login, password)).to be_false
    end

    it "fails if ldap is disabled" do
      Gitlab::LDAP::Config.stub(enabled?: false)
      expect(klass.login(login, password)).to be_false
    end

    it "fails if no login is supplied" do
      expect(klass.login('', password)).to be_false
    end

    it "fails if no password is supplied" do
      expect(klass.login(login, '')).to be_false
    end
  end
end