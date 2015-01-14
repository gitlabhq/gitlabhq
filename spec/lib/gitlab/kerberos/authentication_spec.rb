require 'spec_helper'

describe Gitlab::Kerberos::Authentication do
  let(:klass) { Gitlab::Kerberos::Authentication }
  let(:user) { create(:omniauth_user, provider: :kerberos, extern_uid: 'gitlab') }
  let(:login) { 'john' }
  let(:password) { 'password' }

  describe :login do
    before do
      Devise.stub(omniauth_providers: [:kerberos])
    end

    it "finds the user if authentication is successful" do
      kerberos_realm = user.email.sub(/.*@/, '')
      ::Krb5Auth::Krb5.any_instance.stub(get_init_creds_password: true)
      ::Krb5Auth::Krb5.any_instance.stub(get_default_realm: kerberos_realm)

      expect(klass.login('gitlab', password)).to be_true
    end

    it "returns false if there is no such user in kerberos" do
      kerberos_login = "some-login"
      kerberos_realm = user.email.sub(/.*@/, '')
      ::Krb5Auth::Krb5.any_instance.stub(get_init_creds_password: true)
      ::Krb5Auth::Krb5.any_instance.stub(get_default_realm: kerberos_realm)

      expect(klass.login(kerberos_login, password)).to be_false
    end
  end
end