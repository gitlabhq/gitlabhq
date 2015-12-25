require 'spec_helper'

describe Gitlab::Kerberos::Authentication do
  let(:klass) { Gitlab::Kerberos::Authentication }
  let(:user) { create(:omniauth_user, provider: :kerberos, extern_uid: 'gitlab@FOO.COM') }
  let(:login) { 'john' }
  let(:password) { 'password' }

  describe :kerberos_default_realm do
    it "returns the default realm exposed by the Kerberos library" do
      allow_any_instance_of(::Krb5Auth::Krb5).to receive_messages(get_default_realm: "FOO.COM")

      expect(klass.kerberos_default_realm).to eq("FOO.COM")
    end
  end

  describe :login do
    before do
      allow(Devise).to receive_messages(omniauth_providers: [:kerberos])
      user # make sure user is instanciated
    end

    it "finds the user if authentication is successful (login without kerberos realm)" do
      allow_any_instance_of(::Krb5Auth::Krb5).to receive_messages(get_init_creds_password: true, get_default_principal: 'gitlab@FOO.COM')

      expect(klass.login('gitlab', password)).to be_truthy
    end

    it "finds the user if authentication is successful (login with a kerberos realm)" do
      allow_any_instance_of(::Krb5Auth::Krb5).to receive_messages(get_init_creds_password: true, get_default_principal: 'gitlab@FOO.COM')

      expect(klass.login('gitlab@FOO.COM', password)).to be_truthy
    end

    it "returns false if there is no such user in kerberos" do
      kerberos_login = "some-login"
      allow_any_instance_of(::Krb5Auth::Krb5).to receive_messages(get_init_creds_password: true, get_default_principal: 'some-login@FOO.COM')

      expect(klass.login(kerberos_login, password)).to be_falsy
    end
  end
end
