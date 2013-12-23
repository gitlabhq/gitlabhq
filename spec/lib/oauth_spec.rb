require 'spec_helper'

describe Gitlab::OAuth::User do
  let(:gl_auth) { Gitlab::OAuth::User }

  before do
    Gitlab.config.stub(omniauth: {})

    @info = double(
      uid: '12djsak321',
      name: 'John',
      email: 'john@mail.com'
    )
  end

  describe :create do
    it "should create user from LDAP" do
      @auth = double(info: @info, provider: 'ldap')
      user = gl_auth.create(@auth)

      user.should be_valid
      user.extern_uid.should == @info.uid
      user.provider.should == 'ldap'
    end

    it "should create user from Omniauth" do
      @auth = double(info: @info, provider: 'twitter')
      user = gl_auth.create(@auth)

      user.should be_valid
      user.extern_uid.should == @info.uid
      user.provider.should == 'twitter'
    end

    it "should apply defaults to user" do
      @auth = double(info: @info, provider: 'ldap')
      user = gl_auth.create(@auth)

      user.should be_valid
      user.projects_limit.should == Gitlab.config.gitlab.default_projects_limit
      user.can_create_group.should == Gitlab.config.gitlab.default_can_create_group
    end
  end
end
