require 'spec_helper'

describe Gitlab::Auth do
  let(:gl_auth) { Gitlab::Auth.new }

  describe :find do
    before do
      @user = create(
        :user,
        username: 'john',
        password: '88877711',
        password_confirmation: '88877711'
      )
    end

    it "should find user by valid login/password" do
      expect(gl_auth.find('john', '88877711')).to eq(@user)
    end

    it "should not find user with invalid password" do
      expect(gl_auth.find('john', 'invalid11')).not_to eq(@user)
    end

    it "should not find user with invalid login and password" do
      expect(gl_auth.find('jon', 'invalid11')).not_to eq(@user)
    end
  end
end
