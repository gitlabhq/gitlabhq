require 'spec_helper'

describe Gitlab::Auth do
  let(:gl_auth) { Gitlab::Auth.new }

  describe :find do
    let!(:user) do
      create(:user,
        username: username,
        password: password,
        password_confirmation: password)
    end
    let(:username) { 'john' }
    let(:password) { 'my-secret' }

    it "should find user by valid login/password" do
      expect( gl_auth.find(username, password) ).to eql user
    end

    it "should not find user with invalid password" do
      password = 'wrong'
      expect( gl_auth.find(username, password) ).to_not eql user
    end

    it "should not find user with invalid login" do
      user = 'wrong'
      expect( gl_auth.find(username, password) ).to_not eql user
    end
  end
end
