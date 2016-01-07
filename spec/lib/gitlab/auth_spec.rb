require 'spec_helper'

describe Gitlab::Auth, lib: true do
  let(:gl_auth) { Gitlab::Auth.new }

  describe :find do
    let!(:user) do
      create(:user,
        username: username,
        password: password,
        password_confirmation: password)
    end
    let(:username) { 'John' }     # username isn't lowercase, test this
    let(:password) { 'my-secret' }

    it "should find user by valid login/password" do
      expect( gl_auth.find(username, password) ).to eql user
    end

    it 'should find user by valid email/password with case-insensitive email' do
      expect(gl_auth.find(user.email.upcase, password)).to eql user
    end

    it 'should find user by valid username/password with case-insensitive username' do
      expect(gl_auth.find(username.upcase, password)).to eql user
    end

    it "should not find user with invalid password" do
      password = 'wrong'
      expect( gl_auth.find(username, password) ).not_to eql user
    end

    it "should not find user with invalid login" do
      user = 'wrong'
      expect( gl_auth.find(username, password) ).not_to eql user
    end

    context "with ldap enabled" do
      before do
        allow(Gitlab::LDAP::Config).to receive(:enabled?).and_return(true)
      end

      it "tries to autheticate with db before ldap" do
        expect(Gitlab::LDAP::Authentication).not_to receive(:login)

        gl_auth.find(username, password)
      end

      it "uses ldap as fallback to for authentication" do
        expect(Gitlab::LDAP::Authentication).to receive(:login)

        gl_auth.find('ldap_user', 'password')
      end
    end
  end
end
