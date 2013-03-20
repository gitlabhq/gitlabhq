require 'spec_helper'

describe Gitlab::Auth do
  let(:gl_auth) { Gitlab::Auth.new }

  before do
    Gitlab.config.stub(omniauth: {})

    @info = mock(
      uid: '12djsak321',
      name: 'John',
      email: 'john@mail.com'
    )
    Devise.stub(omniauth_configs: {
      ldap: double('Ldap', options: {}),
      twitter: double('Twitter', options: {})
    })
  end

  describe :find_for_ldap_auth do
    before do
      @auth = mock(
        uid: '12djsak321',
        info: @info,
        provider: 'ldap'
      )
    end

    it "should find by uid & provider" do
      User.should_receive :find_by_extern_uid_and_provider
      gl_auth.find_for_ldap_auth(@auth)
    end

    it "should update credentials by email if missing uid" do
      user = double('User')
      User.stub find_by_extern_uid_and_provider: nil
      User.stub find_by_email: user
      user.should_receive :update_attributes
      gl_auth.find_for_ldap_auth(@auth)
    end


    it "should create from auth if user does not exist" do
      User.stub find_by_extern_uid_and_provider: nil
      User.stub find_by_email: nil
      gl_auth.should_receive :create_from_omniauth
      gl_auth.find_for_ldap_auth(@auth)
    end
  end

  describe :find_or_new_for_omniauth do
    before do
      @auth = mock(
        info: @info,
        provider: 'twitter',
        uid: '12djsak321',
      )
      @user = double('User', provider: @auth.provider, extern_uid: @auth.uid)
    end

    it "should find user" do
      User.should_receive(:find_by_provider_and_extern_uid) { @user }
      User.should_not_receive :find_by_email
      gl_auth.should_not_receive :create_from_omniauth
      gl_auth.find_or_new_for_omniauth(@auth)
    end

    it "should not create user" do
      User.stub find_by_provider_and_extern_uid: nil
      gl_auth.should_not_receive :create_from_omniauth
      gl_auth.find_or_new_for_omniauth(@auth)
    end

    it "should create user if single_sing_on" do
      Gitlab.config.omniauth['allow_single_sign_on'] = true
      User.stub find_by_provider_and_extern_uid: nil
      User.should_receive :find_by_email
      gl_auth.should_receive :create_from_omniauth
      gl_auth.find_or_new_for_omniauth(@auth)
    end

    # FIXME: test find_by_email
    # FIXME: Gitlab::Auth::Error when no uid
  end

  describe :create_from_omniauth do
    it "should create user from LDAP" do
      @auth = double("Auth", info: @info, provider: 'ldap', uid: @info.uid)
      # create_from_omniauth is private
      user = gl_auth.send(:create_from_omniauth, @auth, true)

      user.should be_valid
      user.extern_uid.should == @info.uid
      user.provider.should == 'ldap'
    end

    it "should create user from Omniauth" do
      @auth = double("Auth", info: @info, provider: 'twitter', uid: @info.uid)
      # create_from_omniauth is private
      user = gl_auth.send(:create_from_omniauth, @auth, false)

      user.should be_valid
      user.extern_uid.should == @info.uid
      user.provider.should == 'twitter'
    end

    # FIXME: test block_auto_created_users
    # FIXME: test Gitlab::Auth::Error when no email
  end
end
