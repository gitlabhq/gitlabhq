require 'spec_helper'

describe Gitlab::OAuth::User do
  let(:gl_auth) { Gitlab::OAuth::User }

  before do
    Gitlab.config.stub(omniauth: {})

    @info = double(
      uid: '12djsak321',
      nickname: 'john',
      name: 'John',
      email: 'john@mail.com'
    )
  end

  describe :create do
    it "should create user from LDAP" do
      @auth = double(info: @info, provider: 'ldap')
      user = gl_auth.create(@auth)

      expect(user).to be_valid
      expect(user.extern_uid).to eq(@info.uid)
      expect(user.provider).to eq('ldap')
    end

    it "should create user from Omniauth" do
      @auth = double(info: @info, provider: 'twitter')
      user = gl_auth.create(@auth)

      expect(user).to be_valid
      expect(user.extern_uid).to eq(@info.uid)
      expect(user.provider).to eq('twitter')
    end

    it "should apply defaults to user" do
      @auth = double(info: @info, provider: 'ldap')
      user = gl_auth.create(@auth)

      expect(user).to be_valid
      expect(user.projects_limit).to eq(Gitlab.config.gitlab.default_projects_limit)
      expect(user.can_create_group).to eq(Gitlab.config.gitlab.default_can_create_group)
    end
  end
end
