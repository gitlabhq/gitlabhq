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


    it "should create from auth if user doesnot exist"do
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
    end

    it "should find user"do
      User.should_receive :find_by_provider_and_extern_uid
      gl_auth.should_not_receive :create_from_omniauth
      gl_auth.find_or_new_for_omniauth(@auth)
    end

    it "should not create user"do
      User.stub find_by_provider_and_extern_uid: nil
      gl_auth.should_not_receive :create_from_omniauth
      gl_auth.find_or_new_for_omniauth(@auth)
    end

    it "should create user if single_sing_on"do
      Gitlab.config.omniauth['allow_single_sign_on'] = true
      User.stub find_by_provider_and_extern_uid: nil
      gl_auth.should_receive :create_from_omniauth
      gl_auth.find_or_new_for_omniauth(@auth)
    end
  end

  describe :create_from_omniauth do
    before do
      @raw_info = {
        cn: 'john',
        nickname: 'jonny'
      }

      @ldap_auth = mock(
        info: @info,
        extra: mock(raw_info: @raw_info),
        provider: 'ldap'
      )
    end

    it "should create user from LDAP" do
      user = gl_auth.create_from_omniauth(@ldap_auth, true)

      user.should be_valid
      user.extern_uid.should == @info.uid
      user.provider.should == 'ldap'
    end

    it "should create user from Omniauth" do
      @auth = mock(info: @info, provider: 'twitter')
      user = gl_auth.create_from_omniauth(@auth, false)

      user.should be_valid
      user.extern_uid.should == @info.uid
      user.provider.should == 'twitter'
    end

    it "should still import without extra mapping" do
      Gitlab.config.stub(omniauth: {})
      user = gl_auth.create_from_omniauth(@ldap_auth, true)

      user.should be_valid
      user.extern_uid.should == @info.uid
      user.provider.should == 'ldap'
    end

    it "should have user details from procs" do
      Gitlab.config.stub(omniauth: {}, user_mapping: {})
      Gitlab.config.user_mapping[:name] = ->(auth) { 'TestName' }
      Gitlab.config.user_mapping[:email] = ->(auth) { 'email@somewhere.com' }
      Gitlab.config.user_mapping[:username] = ->(auth) { 'TestUsername' }

      user = gl_auth.create_from_omniauth(@ldap_auth, true)
      user.should be_valid
      user.extern_uid.should == @info.uid
      user.name.should == 'TestName'
      user.email.should == 'email@somewhere.com'
      user.username.should == 'TestUsername'
    end

    it "should modify value using proc" do
      Gitlab.config.stub(omniauth: {}, user_mapping: {})
      Gitlab.config.user_mapping[:username] = ->(auth) { auth.info.email.to_s.downcase.split('@').first }

      user = gl_auth.create_from_omniauth(@ldap_auth, true)
      user.should be_valid
      user.extern_uid.should == @info.uid
      user.username.should == 'john'
    end

    it "should be able to use raw ldap information through simple ldap mapping" do
      Gitlab.config.stub(omniauth: {}, ldap_mapping: {})
      Gitlab.config.ldap_mapping[:name] = 'cn'

      user = gl_auth.create_from_omniauth(@ldap_auth, true)
      user.should be_valid
      user.extern_uid.should == @info.uid
      user.name.should == 'john'
    end

    it "should raise an error if an invalid field is in ldap mapping" do
      Gitlab.config.stub(omniauth: {}, ldap_mapping: {})
      Gitlab.config.ldap_mapping[:name] = 'invalid'

      expect {
        gl_auth.create_from_omniauth(@ldap_auth, true)
      }.to raise_error
    end
  end
end
